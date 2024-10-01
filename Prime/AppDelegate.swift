import UIKit
import Branch
import Firebase
import DeviceKit
import GoogleMaps
import RestaurantSDK
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private lazy var pushService = FirebasePushNotificationService.shared
    private lazy var authService = LocalAuthService.shared
    private lazy var deeplinkService = DeeplinkService.shared
    private lazy var taskService = TaskService.shared

	private let richPushesHandler = RichPushesHandler()

	lazy var window: UIWindow? = PrimeWindow.main

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
		self.clearStaleKeychainDataOnFirstRun()
		self.initDebugValues()

		self.setupFirebase()
		self.logAppStarted()

		self.setupThemes()
		self.makeWindow()
		self.placeAppVersionLabel()
        self.setupPluralization()

		onGlobal {
			RealmPersistence.initPersistenceServices()
			RestaurantSDK.RealmPersistence.initPersistenceServices()
		}

		RestaurantSDK.Config.isProdEnabled = Config.isProdEnabled
		GMSServices.provideAPIKey(RestaurantSDK.Config.googleMapsKey)

		UNUserNotificationCenter.current().delegate = self

		_ = DocumentsCacheService.shared
		_ = NetworkMonitor.shared // Start network monitor
		_ = VersionService.shared // Start min version monitor
        _ = RestaurantSDKNotificationsHandler.shared

		self.setupBranch(launchOptions)
		
		return true
    }

	private func setupFirebase() {
		FirebaseApp.configureIfNeeded()
	}

	private func logAppStarted() {
		let version = "VERSION: \(Bundle.main.releaseWithBuildVersionNumber)"
		let device = "DEVICE: \(Device.current.description), \(Device.current.systemName^) \(Device.current.systemVersion^)"
		DebugUtils.shared.log(sender: self, "\n\n***********\nAPP STARTED. \(version)\n\(device)\n***********\n")
	}

	private func setupThemes() {
		DebugUtils.shared.log(sender: self, "WILL SETUP THEMES")

		Palette.shared.update(from: "Palette")
		Theme.shared.update(from: "Theme")

		UIButton.adaptThemedAttributedTitles()
		UIRefreshControl.adaptThemes()
		NSAttributedString.adaptThemes()
		UIToolbar.makeBarButtonItemsAdaptThemes()
		UINavigationBar.makeBarButtonItemsAdaptThemes()

		UIViewController.notifyOnViewDidDisappear()
	}

	private func setupBranch(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
		// while we're using test key
		let useTestKey = UserDefaults[bool: "branchDebugKey"]
		Branch.setUseTestBranchKey(useTestKey)
		 // listener for Branch Deep Link data
		Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
			if let deepLinkPath = params?[Config.deepLinkPath] as? String,
			   let url = URL(string: "\(Config.appUrlSchemePrefix)://\(deepLinkPath)") {
				self.handleBranchLink(url, withParams: params)
			}
		}

		if LocalAuthService.shared.isAuthorized {
			Branch.getInstance().setIdentity(LocalAuthService.shared.user?.username)
		}

		Notification.onReceive(.loggedIn) { _ in
			Branch.getInstance().setIdentity(LocalAuthService.shared.user?.username)
		}

		Notification.onReceive(.loggedOut) { _ in
			Branch.getInstance().logout()
		}

		Notification.onReceive(.shouldClearCache, .loggedOut) { [weak self] _ in
			self?.taskService = .shared
		}
	}

	func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
		self.deeplinkService.process(url: url)
		return true
	}
    
    // MARK: - Branch Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		
		if Branch.getInstance().continue(userActivity) {
			return true
		}

		if let url = userActivity.webpageURL,
		   self.deeplinkService.process(url: url) {
			return true
		}

        return true
    }

    // MARK: - Notifications

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        self.handle(response.notification)
		self.richPushesHandler.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
		DebugUtils.shared.log(sender: self, "PUSH RECEIVED userNotificationCenter willPresent notification :\n\(notification.request.content.userInfo)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
		DebugUtils.shared.log(sender: self, "PUSH RECEIVED didReceiveRemoteNotification:\n\(userInfo)")

		var doesRequestUpdate = userInfo["requestsUpdate"] as? String == "true"
		doesRequestUpdate = doesRequestUpdate || userInfo["chatUpdate"] as? String == "true"
		doesRequestUpdate = doesRequestUpdate || userInfo["calendarUpdate"] as? String == "true"

        guard doesRequestUpdate else { return }

		self.tasksUpdateDebouncer.reset()
    }

    // MARK: - Private

    private func makeWindow() {
		UIViewController.startTrackingDidAppearDidDisappear()
		
        self.window?.makeKeyAndVisible()
        self.window?.rootViewController = ApplicationContainerAssembly().make()
    }

    private func handle(_ notification: UNNotification) {
		let userInfo = notification.request.content.userInfo
        let deeplink = userInfo["url"] as? String

        guard let deeplink, var url = URL(string: deeplink) else {
			DebugUtils.shared.log(sender: self, "Deeplink is empty/invalid: \(String(describing: deeplink))")
			return
        }

		if let message_guid = userInfo["message_guid"] as? String {
			url[queryItem: "message_guid"] = message_guid
		}

		self.deeplinkService.process(url: url)
    }

	private lazy var tasksUpdateDebouncer = Debouncer(timeout: 1) { [weak self] in
		self?.updateTasksFromPush(UIApplication.shared)
	}

	private func updateTasksFromPush(_ application: UIApplication) {
		let state = application.applicationState
		DebugUtils.shared.log(sender: self, "\(#function) state: \(state)")

		if state == .active {
			Notification.post(.tasksUpdateRequested)
			return
		}

		attempt { [weak self] retryToken in
			self?.taskService.loadTasksSequentially(order: .newer, continueLoading: retryToken)
		}
	}

	private func initDebugValues() {
		UserDefaults.standard
			.register(defaults: [
				"aeroticketsEnabled": Config.aeroticketsEnabled,
				"tinkoffPinEnabled": true,
				"logoutIfDeletedAtFound": true,
				"branchDebugKey": !Config.isProdEnabled,
                "aviaEnabled": Config.aviaModuleEnabled,
                "promoCategoriesEnabled": Config.promoCategoriesEnabled,
                "bannersEnabled": Config.bannersEnabled,
				"vipLoungeEnabled": Config.vipLoungeEnabled,
				"addToWalletEnabled": Config.addToWalletEnabled,
				"addressTapEnabled": true,
				"googleMapRestsEnabled": true,
				"profile.settings.toggle.password": true,
				"restUpdateTagsOnLocationChange": true,
				"TASKS_BATCH_COUNT": 50,
				"backgroundLogoutTimeout": 300,
				"travellerSplashTimeout": 0,
				"assistantPhoneNumber": Config.assistantPhoneNumber,
				"clubPhoneNumber": Config.clubPhoneNumber,
				"clubWebsiteURL": Config.clubWebsiteURL,
				"bugIsVisible": false
			]
		)
	}

	private func clearStaleKeychainDataOnFirstRun() {
		if UserDefaults[bool: "HasRunAfterReinstallAtLeastOnce"] {
			return
		}

		Config.reset()
		LocalAuthService.shared.removeAuthorization()
		FirebasePushNotificationService.shared.clearToken()

		UserDefaults[bool: "HasRunAfterReinstallAtLeastOnce"] = true
	}

    private func handleBranchLink(_ url: URL, withParams params: [AnyHashable : Any]?) {
        var deeplinkPath = url
        if let canonicalUrl = params?[Config.deepLinkCanonicalURL] as? String {
            deeplinkPath.appendPathComponent(canonicalUrl)
        } else if let customUrl = params?[Config.deepLinkCustomURL] as? String {
            deeplinkPath.appendPathComponent(customUrl)
        }
        
		self.deeplinkService.process(url: deeplinkPath)
    }

	private func placeAppVersionLabel() {
		let label = UILabel { (label: UILabel) in
			label.textColor = UIColor.systemPink
			label.font = .boldSystemFont(ofSize: 72)
			label.numberOfLines = 1
			label.lineBreakMode = .byWordWrapping
			label.adjustsFontSizeToFitWidth = true
			label.backgroundColor = .white
			label.alpha = 0.005
		}

		let appName = Bundle.main.appName
		label.text = "\(appName): \(Bundle.main.releaseWithBuildVersionNumber)"

		FloatingControlsView.shared.addSubview(label)
		label.make(.edges(except: .bottom), .equalToSuperview, [35, 20, -20])
	}
}
