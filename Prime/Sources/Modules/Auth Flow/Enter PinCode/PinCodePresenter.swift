import AppTrackingTransparency
import LocalAuthentication
import PromiseKit
import UIKit

extension Notification.Name {
	static let shouldClearPinCodePins = Notification.Name(rawValue: "shouldClearPinCodePins")
}

protocol PinCodePresenterProtocol: AnyObject {
    func didLoad()
	func didAppear()
    func onPinEntered(_ pin: String)

	func authenticate()
	func logout()
}

final class PinCodePresenter: PinCodePresenterProtocol {
    private static let maxNumberOfWrongAttempts = 3
	private static var autologinNextBiometrics = false
    private static var shouldRequestNextBiometrics = true

    weak var view: PinCodeViewControllerProtocol?

    private var authService: LocalAuthServiceProtocol
    private var authEndpoint: AuthEndpointProtocol

    typealias ResetPinBlock = () -> Void
    private let completion: ((Bool, PinCodeMode, ResetPinBlock?) -> Void)?
    private var policy: LAPolicy?

    private var mode: PinCodeMode
    private let shouldDismiss: Bool
    private let phone: String?
    private var latestEnteredPin: String?
    private var numberOfWrongAttempts = 1
    private var biometry: Biometry?
    private var shouldRequestBiometryPermission: Bool = false
	private var pendingAuthenticationBlock: (() -> Void)?

    init(
        mode: PinCodeMode,
        phone: String?,
        authEndpoint: AuthEndpointProtocol,
        localAuthService: LocalAuthServiceProtocol,
        shouldDismiss: Bool,
        completion: @escaping ((Bool, PinCodeMode, ResetPinBlock?) -> Void)
    ) {
        self.authEndpoint = authEndpoint
        self.authService = localAuthService
        self.mode = mode
        self.phone = phone
        self.shouldDismiss = shouldDismiss
        self.completion = completion

		Notification.onReceive(UIApplication.didBecomeActiveNotification) { [weak self] _ in
			self?.pendingAuthenticationBlock?()
		}
    }

    // MARK: - Public API

    func didLoad() {
        self.identifyAuthenticationType()
		self.view?.set(viewModel: self.makeViewModel(action: .inputPin))
        if case .login = self.mode, Self.shouldRequestNextBiometrics {
            self.authenticate()
        }
        Self.shouldRequestNextBiometrics = true
    }

	func didAppear() {
		self.requestAppTrackingThen {
			// nothing
		}
	}

	func onPinEntered(_ pin: String) {
		switch self.mode {
			case .createPin:
				self.savePinAndRouteToConfirmation(pin: pin)
			case .confirmPin:
				self.verifyPinAndRouteToLogin(pin: pin)
			case .login:
				self.loginAndRouteToHomeScreen(with: pin)
		}
	}

    func logout() {
        self.complete(successStatus: false)

        Notification.post(.loggedOut)
		Notification.post(.shouldClearCache)
    }

    // MARK: - Private API
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

	private func savePinAndRouteToConfirmation(pin: String) {
		self.latestEnteredPin = pin
		self.mode = .confirmPin
		self.view?.set(viewModel: self.makeViewModel(action: .confirmPin))
	}

	private func verifyPinAndRouteToLogin(pin: String) {
		guard self.latestEnteredPin == pin else {
			self.latestEnteredPin = nil
			self.mode = .createPin
			self.view?.set(viewModel: self.makeViewModel(action: .notifyError))
			return
		}

		self.view?.showLoadingIndicator()
		self.view?.updateUserInteraction(isEnabled: false)

		DispatchQueue.global(qos: .userInitiated).promise { () -> Promise<EmptyResponse> in
			let phone = self.phone ??
			self.authService.phoneNumberUsedForAuthorization ??
			self.authService.user?.phone ?? ""

			return self.authEndpoint.set(password: pin, phone: phone).promise
		}.done { [weak self] _ in
			guard let self = self else { return }

			defer {
				self.mode = .login(username: self.authService.user?.firstName ?? "")
				self.view?.set(viewModel: self.makeViewModel(action: .inputPin))
			}

			self.authService.pinCode = pin
			guard self.biometry != nil, self.shouldRequestBiometryPermission else {
				self.complete(successStatus: true)
				return
			}

			self.requestBiometricPermission {
				self.complete(successStatus: true)
			}
		}.ensure { [weak self] in
			self?.view?.hideLoadingIndicator()
			self?.view?.updateUserInteraction(isEnabled: true)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) Set PIN failed",
					parameters: error.asDictionary
				)

			AlertPresenter.alertCommonError(error)
			DebugUtils.shared.alert(sender: self, "ERROR WHILE SETTING PIN: \(error.localizedDescription)")
		}
	}

	private func loginAndRouteToHomeScreen(with pin: String) {
		guard let savedPin = self.authService.pinCode else {
			self.complete(successStatus: false)
			return
		}

		if pin == savedPin {
			complete(successStatus: true)
			return
		}

		if self.numberOfWrongAttempts == Self.maxNumberOfWrongAttempts {
			self.logout()
			return
		}

		self.numberOfWrongAttempts += 1
		self.view?.set(viewModel: self.makeViewModel(action: .notifyError))
	}

    private func makeViewModel(action: PinCodeShowAction) -> PinCodeViewModel {
        let title: String

        switch self.mode {
        case .createPin:
			title = Localization.localize("pinCode.navigation.createPin.title")
		case .confirmPin:
			title = Localization.localize("pinCode.navigation.repeatPin.title")
        case .login(let name):
            title = "\(Localization.localize("common.welcome")), \(name)"
        }

        return PinCodeViewModel(
            title: title,
            mode: self.mode,
            action: action,
            biometry: self.biometry
        )
    }

	private func complete(successStatus: Bool = true) {
		if successStatus {
			self.view?.fillPins()
			self.view?.resignFirstResponder()
		}

		self.completion?(successStatus, self.mode) { [weak self] in
            // Тот самый ResetPinBlock
            guard let self = self else {
                return
            }
            self.latestEnteredPin = nil
            self.mode = .createPin
            self.view?.set(viewModel: self.makeViewModel(action: .inputPin))
        }

        if self.shouldDismiss {
            self.view?.dismiss()
        }
    }

    private func requestBiometricPermission(onCancel: @escaping () -> Void) {
        let context = LAContext()
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: Localization.localize("pincode.biometrics.title")
        ) { [weak self] success, error in
            guard let strongSelf = self else {
                return
            }

			Self.autologinNextBiometrics = success && (error == nil)

            DispatchQueue.main.async {
                if let error = error {
					DebugUtils.shared.log(sender: self, "\(#function) ERROR: \(error), CODE: \((error as NSError).code)")
                    strongSelf.handleRegistrationError(error as NSError, onCancel: onCancel)
                } else {
                    strongSelf.complete(successStatus: success)
                }
            }
        }
    }

    private func handleRegistrationError(_ error: NSError, onCancel: @escaping () -> Void) {
        guard let error = error as? LAError else {
            return
        }

        switch error.code {
        case .authenticationFailed, .biometryLockout, .biometryNotEnrolled:
            self.requestBiometricPermission(onCancel: onCancel)
        case .appCancel, .userCancel, .systemCancel:
            Self.shouldRequestNextBiometrics = false
			self.view?.set(viewModel: self.makeViewModel(action: .inputPin))
        case .biometryNotAvailable:
            let alert = AlertContollerFactory.makeBiometricErrorAlert(
                okAction: { [weak self] in
                    self?.openAppSettings()
                }, cancelAction: {
                    onCancel()
                }
            )

            ModalRouter(source: self.view, destination: alert).route()
        default:
            break
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            assertionFailure("Expected to work always")
            return
        }

        UIApplication.shared.open(url)
    }

    private func identifyAuthenticationType() {
        let context = LAContext()
        var error: NSError?

		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			self.shouldRequestBiometryPermission = true
		} else {
			if let laError = error as? LAError, laError.code == .biometryNotAvailable {
				self.shouldRequestBiometryPermission = false
			}
		}

        switch context.biometryType {
        case .faceID:
            self.policy = .deviceOwnerAuthenticationWithBiometrics
            self.biometry = .faceID
        case .touchID:
            self.policy = .deviceOwnerAuthentication
            self.biometry = .touchID
        default:
            break
        }
    }

    func authenticate() {
        guard let policy = self.policy, case PinCodeMode.login(_) = self.mode else {
            return
        }

		let authenticationBlock = { [weak self] in
			guard let self = self else {
				return
			}

			self.pendingAuthenticationBlock = nil

			let isAutoLogin: Bool = Self.autologinNextBiometrics
			Self.autologinNextBiometrics = false

			if isAutoLogin {
				self.complete(successStatus: true)
				return
			}

			let context = LAContext()
			context.evaluatePolicy(
				policy,
				localizedReason: Localization.localize("pincode.biometrics.title")
			) { [weak self] success, error in
				guard let strongSelf = self else {
					return
				}

				DispatchQueue.main.async {
					if let error = error {
						strongSelf.handleLogInError(error as NSError)
					} else {
						strongSelf.complete(successStatus: success)
					}
				}
			}
		}

		if UIApplication.shared.applicationState == .active {
			authenticationBlock()
			return
		}

		self.pendingAuthenticationBlock = authenticationBlock
    }

	private func handleLogInError(_ error: NSError) {
		guard let error = error as? LAError else {
			return
		}

		switch error.code {
			case .authenticationFailed:
				self.authenticate()
			default:
				self.view?.set(viewModel: self.makeViewModel(action: .inputPin))
		}
	}
}
