import UIKit

final class AeroticketViewController: UIViewController, AeroticketViewProtocol {
	private let presenter: AeroticketPresenter

	init(presenter: AeroticketPresenter) {
		self.presenter = presenter
		super.init(nibName: nil, bundle: nil)
	}

	override func loadView() {
		self.view = AeroticketView()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.presenter.didLoad()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update(with viewModel: AeroticketViewModel) {
		(self.view as? AeroticketView)?.update(with: viewModel)
	}
}
