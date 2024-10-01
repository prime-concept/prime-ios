import UIKit

final class CardNumberAssembly: Assembly {
    func make() -> UIViewController {
        let presenter = CardNumberPresenter(endpoint: AuthEndpoint())
        let controller = CardNumberViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
