import UIKit

final class PhoneNumberAssembly: Assembly {
    func make() -> UIViewController {
        let presenter = PhoneNumberPresenter(endpoint: AuthEndpoint())
        let controller = PhoneNumberViewController(presenter: presenter)
        presenter.controller = controller
		return NavigationController(
			rootViewController: controller,
			navigationBarClass: CrutchyNavigationBar.self
		)
    }
}
