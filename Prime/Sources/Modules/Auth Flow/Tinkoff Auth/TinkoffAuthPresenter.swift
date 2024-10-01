import Foundation
import UIKit

protocol TinkoffAuthPresenterProtocol {
	func didLoad()
}

final class TinkoffAuthPresenter: TinkoffAuthPresenterProtocol {
    private let endpoint: AuthEndpoint
	private let loginEndpoint = TinkoffLoginEndpoint.shared
	private let phone: String

    weak var controller: TinkoffAuthViewControllerProtocol?

	init(endpoint: AuthEndpoint, phone: String) {
        self.endpoint = endpoint
		self.phone = phone

		Notification.onReceive(.tinkoffAuthSuccess) { [weak self] notification in
			self?.handleAuthSuccess(notification)
		}

		Notification.onReceive(.tinkoffAuthFailed) { [weak self] notification in
			self?.handleAuthFailed(notification)
		}
    }

	func didLoad() {
		let url = TinkoffAuthService.shared.makeAuthorizationURL(phone: self.phone)
		self.controller?.update(with: url)
	}

	private func handleAuthSuccess(_ notification: Notification) {
		let code = notification.userInfo?["code"] as? String
		let verifier = notification.userInfo?["verifier"] as? String
		
		guard let code, let verifier else {
			self.retryAuth()
			return
		}

		let phone = LocalAuthService.shared.inMemoryPhoneNumberUsedForAuthorization
		LocalAuthService.shared.phoneNumberUsedForAuthorization = phone

		self.loginEndpoint.fetchOauthToken(code: code, verifier: verifier).promise.done { accessToken in
			LocalAuthService.shared.update(token: accessToken)

			ProfileEndpoint.shared.getProfile().promise.done { profile in
				LocalAuthService.shared.update(user: profile)
				if profile.deletedAt != nil, UserDefaults[bool: "logoutIfDeletedAtFound"] {
					self.routeToNotMember()
					return
				}

				if UserDefaults[bool: "tinkoffPinEnabled"] {
					self.routeToPinCode()
				} else {
					self.routeToMainPage()
				}
			}.catch { error in
				self.retryAuth()
			}
		}.catch { error in
			self.retryAuth()
		}
	}

	private func handleAuthFailed(_ notification: Notification) {
		guard let error = notification.userInfo?["error"] as? String else {
			self.retryAuth()
			return
		}

		switch error {
			// Переданный client_id не определен на серверной стороне
			// Проверить настройки приложения
			case "invalid_client":
				self.routeToAuthFailed()
			// Параметр state не соответствует переданному на этапе авторизации
			// Возможно попытка взлома приложения. Показать страницу с неуспешной авторизацией
			case "invalid_state", "invalid_code":
				self.routeToAuthFailed()
			// Не получается получить токен Тинькова
			// Повторить попытку авторизации
			case "token_exchange_failed", "token_introspect_failed", "userinfo_exchange_failed",
				"subscription_exchange_failed", "access_denied", "code_generate_failed":
				self.retryAuth()
			// Возвращен профиль пользователя с пустыми данными - не клиент Тинькоф
			// Станьте клиентом ПРАЙМ
			case "invalid_userinfo", "invalid_subscription":
				self.routeToNotMember()
			default:
				return
		}
	}

	private func routeToMainPage() {
		Notification.post(.routingToMainPageRequested)
	}

	private func routeToPinCode() {
		let user = LocalAuthService.shared.user
		let userInfo = ["user": user as Any, "phone": user?.phone as Any]

		Notification.post(.smsCodeVerified, userInfo: userInfo)
	}

	private func retryAuth() {
		AlertPresenter.alertCommonError {
			Notification.post(.routingToNewAuthorizationRequested)
		}
	}

	private func routeToNotMember() {
		self.showContactPrime()
	}

	private func routeToAuthFailed() {
		self.showContactPrime()
	}

	private func showContactPrime() {
		let phone = LocalAuthService.shared.phoneNumberUsedForAuthorization ?? ""
		let assembly = ContactPrimeAssembly(with: phone) { [weak self] in
			guard let self else { return }
			let stack = self.controller?.navigationController?.viewControllers ?? []
			if !stack.isEmpty {
				self.controller?.navigationController?.popViewController(animated: true)
			} else {
				Notification.post(.routingToNewAuthorizationRequested)
			}
		}

		let router = ModalRouter(
			source: UIViewController.topmostPresented,
			destination: assembly.make()
		)
		router.route()
	}
}
