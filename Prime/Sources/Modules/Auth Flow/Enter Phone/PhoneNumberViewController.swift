import UIKit

protocol PhoneNumberViewProtocol: ModalRouterSourceProtocol {
    func updateUserInteraction(isEnabled: Bool)
	func hideKeyboard()
    func reset()
}

final class PhoneNumberViewController: UIViewController {
    private lazy var authView = PhoneNumberView()
    private var presenter: PhoneNumberPresenterProtocol

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    init(presenter: PhoneNumberPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
		self.view = self.authView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.authView.onNextButtonTap = { [weak self] phoneNumber in
            self?.presenter.register(phone: phoneNumber)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		self.title = " "
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.authView.showKeyboard()
	}

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
		self.hideKeyboard()
    }
}

extension PhoneNumberViewController: PhoneNumberViewProtocol {
    func updateUserInteraction(isEnabled: Bool) {
        self.view.isUserInteractionEnabled = isEnabled
	}

    func reset() {
        self.authView.reset()
    }

	func hideKeyboard() {
		self.authView.showKeyboard()
	}
}
