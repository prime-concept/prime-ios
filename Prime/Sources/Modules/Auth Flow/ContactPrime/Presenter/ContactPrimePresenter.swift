import Foundation
import SafariServices
import UIKit

enum PrimeContacts {
	static let site = UserDefaults[string: "clubWebsiteURL"] ?? Config.clubWebsiteURL
	static let phone = UserDefaults[string: "clubPhoneNumber"] ?? Config.clubPhoneNumber

	static func call() {
		guard let number = URL(string: "tel://\(PrimeContacts.phone)") else {
			return
		}
		UIApplication.shared.open(number)
	}

	static func goToSite(from viewController: UIViewController?) {
		guard let url = URL(string: PrimeContacts.site) else {
			return
		}
		let router = SafariRouter(url: url, source: viewController)
		router.route()
	}
}

protocol ContactPrimePresenterProtocol {
    func callPrime()
    func callBack()
    func goToSite()
}

final class ContactPrimePresenter: ContactPrimePresenterProtocol {
    private let phone: String
    private let endpoint: AuthEndpoint
    weak var controller: ContactPrimeViewProtocol?

    init(phone: String, endpoint: AuthEndpoint) {
        self.phone = phone
        self.endpoint = endpoint
    }

    // MARK: - Public APIs

    func callPrime() {
		PrimeContacts.call()
    }

    func callBack() {
        self.controller?.updateUserInteraction(false)
        DispatchQueue.global(qos: .userInitiated).promise {
            self.endpoint.callBack(to: self.phone).promise
        }.done { [weak self] _ in
			self?.controller?.notifyCallRequested()
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) call request failed",
					parameters: error.asDictionary.appending("phone", self.phone)
				)

			self.controller?.notifyCallRequestFailed()
            DebugUtils.shared.alert(sender: self, "ERROR WHILE REQUESTING CALLBACK:\(error.localizedDescription)")
        }.finally { [weak self] in
            self?.controller?.updateUserInteraction(true)
        }
    }

    func goToSite() {
		PrimeContacts.goToSite(from: self.controller)
    }

    // MARK: - Helpers

    private func showAlert(with message: String) {
        let alert = AlertContollerFactory.makeAlert(with: message)
        ModalRouter(source: self.controller, destination: alert).route()
    }
}
