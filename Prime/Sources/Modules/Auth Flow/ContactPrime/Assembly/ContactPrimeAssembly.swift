import UIKit

final class ContactPrimeAssembly: Assembly {
    private let phone: String
	private let onDismiss: (() -> Void)?

	init(with phone: String, onDismiss: (() -> Void)? = nil) {
        self.phone = phone
		self.onDismiss = onDismiss
    }

    func make() -> UIViewController {
        let presenter = ContactPrimePresenter(phone: self.phone, endpoint: AuthEndpoint())
        let controller = ContactPrimeViewController(presenter: presenter)
		controller.onDismiss = self.onDismiss
        presenter.controller = controller
		return NavigationController(
			rootViewController: controller,
			navigationBarClass: CrutchyNavigationBar.self
		)
    }
}
