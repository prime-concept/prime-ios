import Foundation

protocol PhoneNumberPresenterProtocol {
    func register(phone: String)
}

final class PhoneNumberPresenter: PhoneNumberPresenterProtocol {
    private let endpoint: AuthEndpoint
    weak var controller: PhoneNumberViewProtocol?

    init(endpoint: AuthEndpoint) {
        self.endpoint = endpoint
    }

    // MARK: - Public APIs

    func register(phone: String) {
        guard let phone = SanitizedPhoneNumber(from: phone)?.number else {
            return
        }
        
        AnalyticsReportingService.shared.requestedSMSCode()

		let viewController = PhoneVerificationFactory.make(phone: phone)
		let router = PushRouter(source: self.controller, destination: viewController)

#if TINKOFF
		LocalAuthService.shared.inMemoryPhoneNumberUsedForAuthorization = phone
		router.route()
		return
#else
		LocalAuthService.shared.phoneNumberUsedForAuthorization = phone

		router.route()
        self.controller?.updateUserInteraction(isEnabled: false)

        DispatchQueue.global(qos: .userInitiated).promise {
            self.endpoint.register(phone: phone).promise
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) Enter phone login step failed",
					parameters: error.asDictionary
				)

			AlertPresenter.alertCommonError(error) {
				router.pop()
			}
            DebugUtils.shared.alert(sender: self, "ERROR WHILE REGISTER:\(error.localizedDescription)")
        }.finally { [weak self] in
            self?.controller?.updateUserInteraction(isEnabled: true)
        }
#endif
    }
}
