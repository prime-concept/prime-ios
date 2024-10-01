import UIKit

protocol CardNumberViewControllerProtocol: ModalRouterSourceProtocol {
    func updateUserInteraction(isEnabled: Bool)
    func hideKeyboard()
    func showErrorAlert(with model: CardNumberErrorViewModel)
}

final class CardNumberViewController: UIViewController {
    private lazy var cardView = CardNumberView()
    private var presenter: CardNumberPresenterProtocol
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    init(presenter: CardNumberPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
		self.view = ScrollableStack(
			.vertical,
			arrangedSubviews: [cardView],
			tracksKeyboard: true
		)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.cardView.onNextButtonTap = { [weak self] cardNumber in
            self?.presenter.verify(card: cardNumber)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = " "
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cardView.showKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideKeyboard()
    }
}

extension CardNumberViewController: CardNumberViewControllerProtocol {
    func showErrorAlert(with model: CardNumberErrorViewModel) {
        self.cardView.showErrorAlert(with: model)
    }
    
    func updateUserInteraction(isEnabled: Bool) {
        self.view.isUserInteractionEnabled = isEnabled
    }

    func hideKeyboard() {
        self.cardView.showKeyboard()
    }
}


