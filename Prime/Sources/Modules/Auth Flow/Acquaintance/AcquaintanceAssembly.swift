import UIKit

final class AcquaintanceAssembly: Assembly {
    func make() -> UIViewController {
        let presenter = AcquaintancePresenter(endpoint: AuthEndpoint())
        let controller = AcquaintanceViewController(presenter: presenter)
        presenter.controller = controller
		return NavigationController(
			rootViewController: controller,
			navigationBarClass: CrutchyNavigationBar.self
		)
    }
}
