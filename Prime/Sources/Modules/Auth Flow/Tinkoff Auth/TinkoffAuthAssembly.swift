import UIKit

final class TinkoffAuthAssembly: Assembly {
	private let phone: String

	init(phone: String) {
		self.phone = phone
	}

	func make() -> UIViewController {
		let presenter = TinkoffAuthPresenter(endpoint: AuthEndpoint(), phone: self.phone)
        let controller = TinkoffAuthViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
