import UIKit

protocol SMSCodeViewProtocol: ModalRouterSourceProtocol {
    func alert(title: String, with message: String, completion: ((UIAlertAction) -> Void)?)
    func activateSendCode()
    func activateCodeTimer()
    func showWrongCodeState()
    func updateUserInteraction(isEnabled: Bool)
}

final class SMSCodeViewController: UIViewController {
    private lazy var verificationView = self.view as? SMSCodeView
    private let presenter: SMSCodePresenterProtocol

	private lazy var timer = PersistableTimer(timeout: 60) { [weak self] secondsLeft in
		let secondsLeft = max(0, secondsLeft)
		self?.verificationView?.updateTimer(tick: secondsLeft + 1)

		if secondsLeft == 0 {
			self?.verificationView?.stopTimer()
		}
	}

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    init(presenter: SMSCodePresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = SMSCodeView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupVerificationView()
		self.startTimer()
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBar.tintColorThemed = Palette.shared.gray5
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.verificationView?.showKeyboard()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.verificationView?.hideKeyboard()
	}

    // MARK: - Private

    private func startTimer() {
        self.verificationView?.startTimer()
		self.timer.start()
    }

    private func setupVerificationView() {
        self.verificationView?.onSMSCodeEntered = { [weak self] code in
            self?.presenter.verify(sms: code)
        }
        self.verificationView?.onReceiveCodeButtonTap = { [weak self] in
            self?.presenter.register()
        }
		self.verificationView?.onLoginProblemsButtonTap = { [weak self] in
			self?.presenter.resolveLoginProblems()
		}
    }
}

extension SMSCodeViewController: SMSCodeViewProtocol {
    func alert(title: String, with message: String, completion: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let backAction = UIAlertAction(
            title: Localization.localize("common.back"),
            style: .default,
            handler: completion
        )
        alertController.addAction(backAction)

        ModalRouter(source: self, destination: alertController).route()
    }

    func activateSendCode() {
		self.verificationView?.stopTimer()
    }

    func activateCodeTimer() {
        self.startTimer()
    }

    func showWrongCodeState() {
        self.verificationView?.setWrongState()
    }

    func updateUserInteraction(isEnabled: Bool) {
        self.view.isUserInteractionEnabled = isEnabled
    }
}
