import Foundation

protocol AcquaintancePresenterProtocol {
    func register(surname: String, name: String, phone: String, email: String)
}

final class AcquaintancePresenter: AcquaintancePresenterProtocol {
    private let endpoint: AuthEndpoint
    weak var controller: AcquaintanceViewControllerProtocol?

    init(endpoint: AuthEndpoint) {
        self.endpoint = endpoint
    }

    // MARK: - Public APIs

    func register(surname: String, name: String, phone: String, email: String) {
        guard let phone = SanitizedPhoneNumber(from: phone)?.number else {
            return
        }

        AnalyticsReportingService.shared.requestedSMSCode()

        LocalAuthService.shared.phoneNumberUsedForAuthorization = phone

		let viewController = PhoneVerificationFactory.make(phone: phone)
        
        let router = PushRouter(source: self.controller, destination: viewController)
        router.route()
        self.controller?.updateUserInteraction(isEnabled: false)

        guard let card = UserDefaults.standard.string(forKey: "abankUserCard") else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).promise {
            self.endpoint.register(
                card: card,
                surname: surname,
                name: name,
                phone: phone,
                email: email
            ).promise
        }.done(on: .main) { _ in
            UserDefaults.standard.removeObject(forKey: "abankUserCard")
        }.catch { error in
            AnalyticsReportingService
                .shared.log(
                    name: "[ERROR] \(Swift.type(of: self)) Enter profile registratin step failed",
                    parameters: error.asDictionary
                )

            AlertPresenter.alertCommonError(error) {
                router.pop()
            }
            DebugUtils.shared.alert(sender: self, "ERROR WHILE REGISTER:\(error.localizedDescription)")
        }.finally { [weak self] in
            self?.controller?.updateUserInteraction(isEnabled: true)
        }
    }
}
