import UIKit
import WebKit
import YandexMobileMetrica
import AppTrackingTransparency
import FirebaseMessaging
import PromiseKit
import SwiftKeychainWrapper

extension Notification.Name {
    static let primeTravellerRequested = Notification.Name("primeTravellerRequested")
	static let routingToMainPageRequested = Notification.Name("routingToMainPageRequested")
	static let routingToNewAuthorizationRequested = Notification.Name("routingToNewAuthorizationRequested")
}

protocol ApplicationContainerPresenterProtocol {
    func didLoad()
}

final class ApplicationContainerPresenter: NSObject, ApplicationContainerPresenterProtocol {
    private let authService: LocalAuthService
    private let onboardingService: OnboardingServiceProtocol
    private let taskPersistenceService: TaskPersistenceServiceProtocol
    private let analyticsService: AnalyticsService
    private let analyticsReporter: AnalyticsReportingServiceProtocol
    private let defaultsService: DefaultsServiceProtocol
    private let authEndpoint: AuthEndpoint

	private var firebaseTokenRegistered = false
	private var expiredSessionAlertIsBeingPresented = false

	private let delegate = ApplicationContainerPresenterDelegate()
    
    weak var controller: ApplicationContainerViewController?
    var appDidEnterBackgroundDate: Date?

    init(
        authService: LocalAuthService,
        onboardingService: OnboardingServiceProtocol,
        taskPersistenceService: TaskPersistenceServiceProtocol,
        analyticsService: AnalyticsService,
        analyticsReporter: AnalyticsReportingServiceProtocol,
        defaultsService: DefaultsServiceProtocol,
        endpoint: AuthEndpoint
    ) {
        self.authService = authService
        self.onboardingService = onboardingService
        self.taskPersistenceService = taskPersistenceService
        self.analyticsService = analyticsService
        self.analyticsReporter = analyticsReporter
        self.defaultsService = defaultsService
        self.authEndpoint = endpoint

		super.init()

		self.startListeningToNotifications()
		self.setupAndListenToFCMToken()

		GoogleLogCleaner.shared.cleanOlderThan14Days()
    }

	private func startListeningToNotifications() {
		Notification.onReceive(
			UIApplication.willEnterForegroundNotification,
			UIApplication.willResignActiveNotification
		) { [weak self] notification in
			DebugUtils.shared.log(sender: self, "APP WILL CHANGE STATE:", notification.description)
		}

		Notification.onReceive(.routingToMainPageRequested, on: .main) { [weak self] _ in
			self?.routeToMainPage()
			Notification.post(.loggedIn)
		}

		Notification.onReceive(.routingToNewAuthorizationRequested, on: .main) { [weak self] _ in
			self?.doLocalLogout()
		}

		Notification.onReceive(.notAMember) { [weak self] _ in
			self?.handleNotAMember()
		}
	}

	private func setupAndListenToFCMToken() {
		if let fcmToken = Messaging.messaging().fcmToken {
			FirebasePushNotificationService.shared.update(token: fcmToken)
			return
		}

		self.startListeningToTokenUpdates()
	}

	private func startListeningToTokenUpdates() {
		Notification.onReceive(.firMessagingRegistrationTokenRefresh) { [weak self] notification in
			let token = (notification.userInfo?["token"] as? String) ??
						(notification.object as? String)

			guard let token = token else {
				return
			}

			FirebasePushNotificationService.shared.update(token: token)
			self?.registerFirebaseTokenIfAuthorized()
		}
	}

    func didLoad() {
        self.setupAnalytics()
		self.subscribeToNotifications()
		self.handleFirstLaunchIfNeeded()
		self.handleNewVersionFirstLaunchIfNeeded()
		self.setupFloatingControlsView()

		self.triggerTravellerLoading()
		
		DebugUtils.shared.log(sender: self, "did load")
		DebugUtils.shared.log(sender: self, "\(#function) UNREAD COUNT PUSH ICON BADGE \(UIApplication.shared.applicationIconBadgeNumber)")

		guard self.delegate.allowsPinCodeLogin else {
			DebugUtils.shared.log(sender: self, "WILL ASK PHONE NUMBER")
			if !self.authService.isAuthorized {
				DebugUtils.shared.log(sender: self, "\(#function) WILL SET UNREAD COUNT PUSH ICON BADGE: 0")
				UIApplication.shared.applicationIconBadgeNumber = 0
			}
			self.openAuthorization()
			return
		}

		guard self.authService.isAuthorized else {
			DebugUtils.shared.log(sender: self, "WILL ASK PHONE NUMBER")
			DebugUtils.shared.log(sender: self, "\(#function) WILL SET UNREAD COUNT PUSH ICON BADGE: 0")
			UIApplication.shared.applicationIconBadgeNumber = 0
			self.openAuthorization()
			return
		}

		if self.skipAuthorizationAndRouteToMainPageIfPossible() {
			DebugUtils.shared.log(sender: self, "USER TURNED OFF PIN/FACE/TOUCH, SKIP AUTH, GOTO MAIN")
			return
		}

		DebugUtils.shared.log(sender: self, "WILL ASK PINCODE")

		let user = self.authService.user
		let name = user?.firstName ?? ""
		let mode: PinCodeMode = self.authService.pinCode == nil ? .createPin : .login(username: name)

		self.askPinCode(user: user, mode: mode)
    }

	private func triggerTravellerLoading() {
		self.travellerController.view.alpha = 0.01
		self.controller?.present(self.travellerController, animated: false)
		delay(0.1) {
			self.travellerController.dismiss(animated: false)
			self.travellerController.view.alpha = 1
		}
	}

    @objc
	private func routeToAcquaintance(_ notification: Notification) {
        self.clearViewControllers()
		let viewController = notification.userInfo?["viewController"]
		guard let viewController = viewController as? UIViewController else {
			return
		}
        self.display(child: viewController)
    }

    @objc
    private func routeToPrimeTraveller(_ notification: Notification) {
        let router = ModalRouter(
            source: self.controller?.topmostPresentedOrSelf,
            destination: self.travellerController,
            modalPresentationStyle: .formSheet
        )

        router.route()
        self.analyticsReporter.openedPrimeTraveller()
    }

	@objc
	private func routeToPincodeCreation(_ notification: Notification) {
		guard let phone = notification.userInfo?["phone"] as? String,
			  let user = notification.userInfo?["user"] as? Profile else {
			assert(false, "[APP CONTAINER PRESENTER] You MUST have a verified phone number and a valid User to create a Pin")
			return
		}

		self.authService.update(user: user)
		self.askPinCode(user: user, phone: phone, mode: .createPin)
	}

	private func subscribeToNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.routeToPincodeCreation(_:)),
			name: .smsCodeVerified,
			object: nil
		)

		Notification.onReceive(.cardNumberVerified, on: .main) { [weak self] notification in
			self?.routeToAcquaintance(notification)
		}

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.routeToPrimeTraveller(_:)),
            name: .primeTravellerRequested,
            object: nil
        )

		Notification.onReceive(.loggedIn, on: .main) { [weak self] _ in
			self?.handleLogin()
		}

		Notification.onReceive(.loggedOut, on: .main) { [weak self] _ in
			self?.handleLogout()
		}

		Notification.onReceive(.shouldClearCache, .loggedOut) { _ in
			TaskType.updateTaskTypesRows([])
			["ru", "en"].forEach{ TaskType.updateCache($0, []) }
		}

		Notification.onReceive(UIApplication.didEnterBackgroundNotification) { [weak self] in
			self?.applicationDidEnterBackground($0)
		}

		Notification.onReceive(UIApplication.willEnterForegroundNotification) { [weak self] in
			self?.applicationWillEnterForeground($0)
		}
	}

	private func handleNewVersionFirstLaunchIfNeeded() {
		let appVersion = Bundle.main.releaseWithBuildVersionNumber
		let key = "\(Bundle.main.appName)_version"

		let storedAppVersion = KeychainWrapper.standard.string(forKey: key)
		if appVersion == storedAppVersion {
			return
		}

		KeychainWrapper.standard.set(appVersion, forKey: key)
		AnalyticsReportingService.shared.newVersionLaunched(appVersion)
	}

	private func handleFirstLaunchIfNeeded() {
		if self.defaultsService.appHasRunBefore {
			return
		}

		self.defaultsService.appHasRunBefore = true

		self.analyticsReporter.launchFirstTime()
		self.authService.removeAuthorization()

		self.showOnboardingIfNeeded()
	}

	private func showOnboardingIfNeeded() {
		guard Config.shouldShowOnboarding else {
			return
		}

		let onboardingViewController = OnboardingAssembly { [weak self] in
			self?.display(child: AuthFlowFirstStepFactory.make())
		}.make()

		self.display(child: onboardingViewController)
	}

    @objc
    func applicationDidEnterBackground(_ notification: Notification) {
        self.appDidEnterBackgroundDate = Date()

		var details = [String: Any]()
        if let title = UIViewController.lastShownViewControllerTitle {
            details["screen"] = title
        }

		AnalyticsReportingService.shared.log(
			name: "Application Moved To Background",
			parameters: details
		)
    }

    @objc
    func applicationWillEnterForeground(_ notification: Notification) {
        guard let previousDate = self.appDidEnterBackgroundDate else { return }
        let calendar = Calendar.current
        let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
        let seconds = difference.second ?? 0

		let timeout = UserDefaults[int: "backgroundLogoutTimeout"]
        if seconds > timeout {
			self.travellerController = with(PrimeTravellerWebViewController()) {
				$0.loadSplashThenRefreshActualWebContent()
			}
			self.reauthorizeAfterLongTimeInBackground()
        }

		var details: [String: Any] = ["seconds": seconds]
        if let title = UIViewController.lastShownViewControllerTitle {
            details[title] = details
        }

		AnalyticsReportingService.shared.log(
			name: "Application Moved To Foreground",
			parameters: details
		)
    }

	private func openAuthorization(completion: (() -> Void)? = nil) {
		delay(0.3) {
			self.controller?.dismissBlockingViewController()
			
			let firstStep = AuthFlowFirstStepFactory.make()
			self.display(child: firstStep) {
				completion?()
			}
		}
	}

	@objc
	private func handleLogin() {
		DebugUtils.shared.log(sender: self, "\n\n******************\n!!! USER LOGGED IN !!!\n******************\n")
		self.subscribeToTokenExpiration()
		self.analyticsReporter.sessionStarted()
	}

    @objc
	private func handleLogout() {
		DebugUtils.shared.log(sender: self, "\n\n******************\n!!! USER LOGGED OUT !!!\n******************\n")

		DispatchQueue.global().promise {
			self.authEndpoint.logout().promise
		}.done { response in
			DebugUtils.shared.log(response)
		}.ensure {
			self.doLocalLogout()
		}.catch { [weak self] error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] Logout failed",
					parameters: error.asDictionary
				)
			DebugUtils.shared.log(sender: self, "ЭРРОР ЛОГАУТА! \(error)")
		}
    }

	private func doLocalLogout(completion: (() -> Void)? = nil) {
		self.travellerController = with(PrimeTravellerWebViewController()) {
			$0.loadSplashThenRefreshActualWebContent()
		}

		LocalAuthService.shared.removeAuthorization()

		self.taskPersistenceService.deleteAll()
		self.unsubscribeFromTokenExpiration()
		self.disablePushNotifications()

		onMain {
			UIApplication.shared.applicationIconBadgeNumber = 0
			DebugUtils.shared.log(sender: self, "\(#function) WILL SET UNREAD COUNT PUSH ICON BADGE: 0")

			self.dismissPresentedAnd {
				self.clearViewControllers()
				self.openAuthorization()
			}
		}
	}

	private func clearViewControllers() {
		self.mainPage = nil
	}

	private func subscribeToTokenExpiration() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.handleTokenRefreshFailed(_:)),
			name: .failedToRefreshToken,
			object: nil
		)
	}

	private func unsubscribeFromTokenExpiration() {
		NotificationCenter.default.removeObserver(
			self,
			name: .failedToRefreshToken,
			object: nil
		)
	}

    @objc
	private func handleTokenRefreshFailed(_ notification: Notification) {
		let error = notification.userInfo?["error"] as? Swift.Error
		guard let error, self.authService.isAuthorized else { return }

		onMain {
			if error.isChangedPinToken {
				DebugUtils.shared.log(sender: self, "ERROR 401 ACCESS TOKEN! SOMEBODY CHANGED PIN!")
				self.routeToEmergencyPinChange()
				return
			}

			if error.isDeletedUserToken {
				DebugUtils.shared.log(sender: self, "ERROR 401 ACCESS TOKEN! DELETED USER DETECTED!")
				Notification.post(.shouldClearCache)
				self.handleNotAMember()
				return
			}

			if error.isNoRefreshToken {
				DebugUtils.shared.log(sender: self, "EXPIRED TOKEN AND NO REFRESH TOKEN, LETS GO TO PHONE AUTH")
				Notification.post(.shouldClearCache)
				self.doLocalLogout()
			}
		}
	}

	private func routeToEmergencyPinChange() {
		if self.expiredSessionAlertIsBeingPresented {
			return
		}

		self.expiredSessionAlertIsBeingPresented = true

		self.authService.removePinAndToken()

		DebugUtils.shared.log(sender: self, "WILL SHOW CHANGE PINCODE ALERT")

		self.alert(
			message: "pinCode.wasChangedOnOtherDevice".localized,
			action: "pinCode.wasChangedOnOtherDevice.reset".localized) {
				self.expiredSessionAlertIsBeingPresented = false
				self.dismissPresentedAnd {
					self.askPinCode(mode: .createPin)
				}
			}
	}

	private func reauthorizeAfterLongTimeInBackground() {
		guard self.authService.isLoggedIn,
		      let user = self.authService.user else {
			return
		}

		DebugUtils.shared.log(sender: self, #function)

		DebugUtils.shared.log(sender: self, "User: \(user.firstName^) \(user.lastName^) \(user.phone^) \(user.username^)")

		let mode = PinCodeMode.login(username: user.firstName^)

		let pinCodeViewController = PinCodeAssembly(mode: mode, phone: user.phone^) { [weak self] success, mode, reenterPin in

			guard success, let self else {
				return
			}

			Notification.post(.loggedIn)

			ProfileService.shared.getProfile(cached: true) { profile in
				self.authService.poke()
				self.controller?.dismissBlockingViewController( {
					UIWindow.keyWindow?.endEditing(true)
				})
			}

			self.fetchOauthToken()

		}.make()

		self.controller?.presentBlocking(pinCodeViewController)
	}

    private func dismissPresentedAnd(_ completion: @escaping () -> Void) {
		let animated = UIApplication.shared.applicationState == .active

        if self.controller?.presentedViewController != nil {
            self.controller?.dismiss(animated: animated, completion: completion)
            return
        }

		self.controller?.dismissBlockingViewController()

        completion()
    }

	private func askPinCode(user: Profile? = nil, phone: String? = nil, mode: PinCodeMode) {
		DebugUtils.shared.log(sender: self, #function)

        if let user = user {
			DebugUtils.shared.log(sender: self, "User: \(user.firstName^) \(user.lastName^) \(user.phone^) \(user.username^)")
        }

        let pinCodeViewController = PinCodeAssembly(mode: mode, phone: phone) { [weak self] success, mode, reenterPin in
            guard success,
				  let self = self,
				  let user = user ?? self.authService.user else {
                return
            }

			guard case .login(username: _) = mode else {
				DispatchQueue.main.async {
					self.askPinCode(user: user, mode: .login(username: user.firstName^))
				}
				return
			}

			self.controller?.showLoadingIndicator()

			// We let user in the app (at least in offline mode), if he has already authorized.
			// Then we request the real oauth token and handle the errors if needed.
			let hasLoggedPreviously = self.authService.token != nil

			if hasLoggedPreviously {
				self.fetchProfileAndRouteToMainPage()
				Notification.post(.loggedIn)
			}

			self.fetchOauthToken(
				done: { [weak self] in
					if !hasLoggedPreviously {
						self?.fetchProfileAndRouteToMainPage()
						Notification.post(.loggedIn)
					}
				},
				onError: { [weak self] error in
					self?.handleTokenError(error, reenterPin)
				})
        }.make()

		self.display(child: pinCodeViewController)
    }

	private func skipAuthorizationAndRouteToMainPageIfPossible() -> Bool {
		if UserDefaults[bool: "profile.settings.toggle.password"] {
			return false
		}

		self.controller?.view.backgroundColorThemed = Palette.shared.gray0
		self.controller?.showLoadingIndicator()

		self.fetchProfileAndRouteToMainPage()

		self.fetchOauthToken(done: { Notification.post(.loggedIn) })

		return true
	}

	private func fetchOauthToken(
		done: (() -> Void)? = nil,
		onError: ((Error) -> Void)? = nil,
		ensure: (() -> Void)? = nil
	) {
		guard let user = self.authService.user,
			  let code = self.authService.pinCode else {
			return
		}

		DispatchQueue.global(qos: .userInitiated).promise { () -> Promise<AccessToken> in
			self.authEndpoint.fetchOauthToken(username: user.username^, code: code).promise
		}.done(on: .main) { accessToken in
			self.authService.auth(user: user, accessToken: accessToken)
			done?()
		}.ensure {
			LocalAuthService.tokenNeedsToBeRefreshed = false
			ensure?()
		}.catch { [weak self] error in
			onError?(error)

			self?.controller?.hideLoadingIndicator()
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) fetchOauthToken failed",
					parameters: error.asDictionary
				)
		}
	}

	private func fetchProfileAndRouteToMainPage() {
		ProfileService.shared.getProfile(cached: true) { profile in
			self.authService.poke()
			self.routeToMainPage()
		}
	}

	private func routeToMainPage() {
		self.requestAppTrackingThen { [weak self] in
			onMain {
				self?.displayMainPage()
				self?.trackSuccessfulLogin()

				PermissionService.shared.requestHomePermissionsIfNeeded(pushesCompletion: { success in
					self?.enablePushNotifications()
				})
			}
		}
	}

	private func handleTokenError(_ error: Error, _ reenterPin: (() -> Void)?) {
		DebugUtils.shared.alert(sender: self, "ERROR WHILE FETCHING OAUTH TOKEN: \(error.localizedDescription)")

		Notification.post(.shouldClearPinCodePins)

		if (error as? Endpoint.Error)?.isChangedPinToken ?? error.isChangedPinToken {
			self.routeToEmergencyPinChange()
			return
		}

		guard (error as NSError).code == 401 else {
			return
		}

		self.alert(
			message: "pinCode.wasChangedOnOtherDevice".localized,
			action: "pinCode.wasChangedOnOtherDevice.reset".localized
		) {
			reenterPin?()
		}
	}

	private func requestCalendarAccessThen(completion: @escaping () -> Void) {
		CalendarEventsService.shared.requestAccess { _, _ in
			completion()
		}
	}

	private func requestAppTrackingThen(completion: @escaping () -> Void) {
		onMain {
			if #available(iOS 14.5, *) {
				let status = ATTrackingManager.trackingAuthorizationStatus
				DebugUtils.shared.log(sender: self, "ATTrackingManager status: \(status)")
				ATTrackingManager.requestTrackingAuthorization { _ in
					completion()
				}
			} else {
				completion()
			}
		}
	}

	private func trackSuccessfulLogin() {
		self.trackCurrentLogin()
		self.trackIfNewUserLoggedIn()
	}

	private func trackCurrentLogin() {
		if self.defaultsService.hasLoginBefore {
			self.analyticsReporter.loggedInTwoTimesOrMore()
			return
		}

		self.defaultsService.hasLoginBefore = true
		self.analyticsReporter.loggedInFirstTime()
	}

	private func trackIfNewUserLoggedIn() {
		guard let username = self.authService.user?.username else {
			return
		}

		var usersEverLoggedToApp: [String] = Keychain[value: "UsersEverLoggedToApp"] ?? []
		if usersEverLoggedToApp.contains(username) {
			return
		}

		usersEverLoggedToApp.append(username)
		Keychain[value: "UsersEverLoggedToApp"] = usersEverLoggedToApp

		self.analyticsReporter.newUserLoggedIn()
	}

	private lazy var debugController = DebugMenuViewController()

	private var travellerController = with(PrimeTravellerWebViewController()) {
		$0.loadSplashThenRefreshActualWebContent()
	}

	private var mainPage: UIViewController?
    
    private var presentationController: UIViewController? {
        let topController = SourcelessRouter().topController
        let isDeeplink = !DeeplinkService.shared.currentDeeplinks.isEmpty
        let controller = isDeeplink ? topController : self.controller
        return controller
    }

	private func setupFloatingControlsView() {
		FloatingControlsView.shared.onGlobePressed ??= { [weak self] in
			FeedbackGenerator.vibrateSelection()

			guard let self = self else { return }

			UIViewController.topmostPresented?.present(self.travellerController, animated: true)

			self.analyticsReporter.openedPrimeTraveller()
		}

		FloatingControlsView.shared.onBellPressed ??= { [weak self] in
			FeedbackGenerator.vibrateSelection()

			guard let self else { return }

			defer { self.analyticsReporter.tappedBell() }

			DeeplinkService.shared.process(deeplink: .createTask(.general))
		}

		FloatingControlsView.shared.onImPrimePressed ??= {
			FeedbackGenerator.vibrateSelection()
			DeeplinkService.shared.process(deeplink: .profile)
		}

		FloatingControlsView.shared.onDebugPressed ??= { [weak self] in
			guard let self = self else { return }
			let router = ModalRouter(
				destination: self.debugController,
				modalPresentationStyle: .formSheet
			)
			router.route()
		}
	}

    private func displayMainPage() {
		let homeAssembly = HomeAssembly { _ in
			self.display(child: self.mainPage!, asMainPage: true)
			delay(0.25) { self.controller?.hideLoadingIndicator() }
		}

		self.mainPage = homeAssembly.make()
    }

	private func display(
		child viewController: UIViewController,
		asMainPage: Bool = false,
		completion: (() -> Void)? = nil)
	{
		self.controller?.displayChild(viewController: viewController, completion: completion)
		LocalAuthService.shared.isOnMainPage = asMainPage
		DebugUtils.shared.isOnMainPage = asMainPage
	}

    private func setupAnalytics() {
        let analyticsService = AnalyticsService()
        analyticsService.setupAnalytics()
    }

    private func alert(title: String = "", message: String, action: String, onAction: (() -> Void)?) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: action, style: .cancel) { _ in
            onAction?()
        }
        alert.addAction(action)

		self.controller?.topmostPresentedOrSelf.present(alert, animated: true, completion: nil)
    }

	private func handleNotAMember() {
		let phone = LocalAuthService.shared.phoneNumberUsedForAuthorization ?? ""
		let contactPrime = {
			let assembly = ContactPrimeAssembly(with: phone) {
				Notification.post(.routingToNewAuthorizationRequested)
			}

			let router = ModalRouter(
				source: UIViewController.topmostPresented,
				destination: assembly.make()
			)
			router.route()
		}

		self.doLocalLogout {
			contactPrime()
		}
	}
}

extension ApplicationContainerPresenter {
	private func registerFirebaseTokenIfAuthorized(_ completion: ((Bool) -> Void)? = nil) {
		guard self.authService.isAuthorized else {
			completion?(false)
			return
		}

		DispatchQueue.global().promise {
			FirebasePushNotificationService.shared.registerToken()
		}.done { _ in
			self.firebaseTokenRegistered = true
			DebugUtils.shared.alert(sender: self, "SUCCESSFULLY REGISTERED FIREBASE TOKEN")
			completion?(true)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] Failed to register firebase token",
					parameters: error.asDictionary
				)

			self.firebaseTokenRegistered = false
			DebugUtils.shared.alert(sender: self, "FAILED TO REGISTER FIREBASE TOKEN: \(error.localizedDescription)")
			completion?(true)
		}
	}

	private func enablePushNotifications() {
		onMain {
			if !self.firebaseTokenRegistered {
				self.registerFirebaseTokenIfAuthorized()
			}
			
			UIApplication.shared.registerForRemoteNotifications()
			
			self.analyticsReporter.pushPermissionGranted()
		}
	}

	private func disablePushNotifications() {
        self.firebaseTokenRegistered = false
		FirebasePushNotificationService.shared.clearToken()
        UIApplication.shared.unregisterForRemoteNotifications()
	}
}
