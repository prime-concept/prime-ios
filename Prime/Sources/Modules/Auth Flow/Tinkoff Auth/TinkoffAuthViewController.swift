import UIKit
import WebKit

protocol TinkoffAuthViewControllerProtocol: ModalRouterSourceProtocol {
	func update(with url: URL)
}

final class TinkoffAuthViewController: UIViewController, TinkoffAuthViewControllerProtocol {
    private var presenter: TinkoffAuthPresenterProtocol
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    
    init(presenter: TinkoffAuthPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

		self.view.backgroundColorThemed = Palette.shared.gray5
		self.presenter.didLoad()
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.colorizeNavbar()
	}

	private func colorizeNavbar() {
		self.navigationController?.navigationBar.tintColorThemed = Palette.shared.gray0
	}

	func update(with url: URL) {
		let tinkoffIdViewController = GenericWebViewController(url: url)

		tinkoffIdViewController.willMove(toParent: self)
		self.view.addSubview(tinkoffIdViewController.view)
		tinkoffIdViewController.view.make(.edges, .equalToSuperview)
		tinkoffIdViewController.view.make(.top, .equal, to: self.view.safeAreaLayoutGuide)
		self.addChild(tinkoffIdViewController)
		tinkoffIdViewController.didMove(toParent: self)
	}
}
