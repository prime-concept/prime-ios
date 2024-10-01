import UIKit

protocol AcquaintanceViewControllerProtocol: ModalRouterSourceProtocol {
    func updateUserInteraction(isEnabled: Bool)
    func hideKeyboard()
    func reset()
}

final class AcquaintanceViewController: UIViewController {
    private lazy var authView = self.view as? AcquaintanceView
    private var presenter: AcquaintancePresenterProtocol

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    init(presenter: AcquaintancePresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = AcquaintanceView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.authView?.onNextButtonTap = { [weak self] surname, name, phoneNumber, email in
            self?.presenter.register(
                surname: surname,
                name: name,
                phone: phoneNumber,
                email: email
            )
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = " "
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.authView?.showKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideKeyboard()
    }
}

extension AcquaintanceViewController: AcquaintanceViewControllerProtocol {
    func updateUserInteraction(isEnabled: Bool) {
        self.view.isUserInteractionEnabled = isEnabled
    }

    func reset() {
        self.authView?.reset()
    }

    func hideKeyboard() {
        self.authView?.showKeyboard()
    }
}
