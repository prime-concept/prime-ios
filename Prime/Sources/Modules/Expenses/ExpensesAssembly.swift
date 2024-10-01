import UIKit

final class ExpensesAssembly: Assembly {
    func make() -> UIViewController {
        let authService = LocalAuthService()
        let presenter = ExpensesPresenter(profileEndpoint: ProfileEndpoint(authService: authService))
        let controller = ExpensesViewController(presenter: presenter)
        controller.modalPresentationStyle = .popover
        controller.modalTransitionStyle = .coverVertical
        presenter.viewController = controller
        return controller
    }
}
