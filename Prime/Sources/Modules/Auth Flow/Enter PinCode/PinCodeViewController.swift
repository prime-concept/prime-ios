import UIKit

protocol PinCodeViewControllerProtocol: ModalRouterSourceProtocol {
    func dismiss()
	func fillPins()
	func clearPins()
    func set(viewModel: PinCodeViewModel)
    func updateUserInteraction(isEnabled: Bool)
}

final class PinCodeViewController: UIViewController {
    private lazy var pinCodeView = self.view as? PinCodeView
    private let presenter: PinCodePresenterProtocol?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    init(presenter: PinCodePresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = PinCodeView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupObserver()
        self.setupPinCodeView()

        self.presenter?.didLoad()
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.presenter?.didAppear()
	}

	override func resignFirstResponder() -> Bool {
		return self.view.resignFirstResponder()
	}

    // MARK: - Private

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    private func setupPinCodeView() {
        self.pinCodeView?.onFaceIDSelected = { [weak self] in
            self?.presenter?.authenticate()
        }
        self.pinCodeView?.onFingerprintSelected = { [weak self] in
            self?.presenter?.authenticate()
        }
        self.pinCodeView?.onPinEntered = { [weak self] pin in
            self?.presenter?.onPinEntered(pin)
        }
        self.pinCodeView?.onLogout = { [weak self] in
            self?.presenter?.logout()
        }
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height

            self.pinCodeView?.setLogoutButtonConstraints(with: keyboardHeight)
			self.pinCodeView?.setNeedsLayout()

			let duration = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGFloat
			UIView.animate(withDuration: duration ?? 0) {
				self.pinCodeView?.layoutIfNeeded()
			}
        }
    }
}

extension PinCodeViewController: PinCodeViewControllerProtocol {
    func set(viewModel: PinCodeViewModel) {
        self.pinCodeView?.update(viewModel: viewModel)

        switch viewModel.action {
        case .notifyError:
            FeedbackGenerator.vibrateLight()

        case .confirmPin:
            FeedbackGenerator.vibrateSelection()

        default:
            break
        }
    }

	func clearPins() {
		self.pinCodeView?.clearPins()
	}

	func fillPins() {
		self.pinCodeView?.fillPins()
	}

    func dismiss() {
        self.dismiss(animated: true)
    }

    func updateUserInteraction(isEnabled: Bool) {
        self.view.isUserInteractionEnabled = isEnabled
    }
}
