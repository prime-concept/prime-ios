import Foundation

protocol CardNumberPresenterProtocol {
    func verify(card: String)
}

final class CardNumberPresenter: CardNumberPresenterProtocol {
    private let endpoint: AuthEndpoint
    weak var controller: CardNumberViewControllerProtocol?

    init(endpoint: AuthEndpoint) {
        self.endpoint = endpoint
    }

    // MARK: - Public APIs

    func verify(card: String) {
        DispatchQueue.global(qos: .userInitiated).promise {
            self.endpoint.verify(card: card).promise
        }.done(on: .main) { _ in
			let viewController = AcquaintanceAssembly().make()
			Notification.post(.cardNumberVerified, userInfo: ["viewController": viewController])
        }.catch { error in
            DebugUtils.shared.alert(sender: self, "ERROR WHILE CARD REGISTER:\(error.localizedDescription)")
            self.controller?.showErrorAlert(with: CardNumberErrorViewModel.make(from: error))
        }.finally { [weak self] in
            self?.controller?.updateUserInteraction(isEnabled: true)
        }
    }
}
