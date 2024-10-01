import UIKit

protocol ContactAdditionViewControllerProtocol: ModalRouterSourceProtocol {
    func setup(with viewModel: ContactAdditionViewModel)
    func set(code: String)
    func set(contactType: ContactTypeViewModel)
    func set(city: City)
    func set(country: Country)
    func presentTypeSelection(with controller: UIViewController, scrollView: UIScrollView?)
    func showDeleteAlert(type: ContactsListType, completion: @escaping () -> Void)
    func showValidationAlert(for field: ContactAdditionFieldType)
    func showActivity()
    func hideActivity()
}

final class ContactAdditionViewController: UIViewController {
    private lazy var selectionPresentationManager = FloatingControllerPresentationManager(
        context: .itemSelection,
        sourceViewController: self
    )

    private lazy var contactAdditionView = ContactAdditionView()
    private let presenter: ContactAdditionPresenterProtocol

    init(presenter: ContactAdditionPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        self.presenter.didLoad()
    }

    // MARK: - Helpers

    private func setup() {
        self.view.backgroundColorThemed = Palette.shared.clear
        self.view.addSubview(self.contactAdditionView)

        self.contactAdditionView.make(.edges, .equalToSuperview)

        self.contactAdditionView.onSave = { [weak self] in
            self?.presenter.addOrEdit()
        }
        self.contactAdditionView.onDelete = { [weak self] in
            self?.presenter.delete()
        }
        self.contactAdditionView.onTapCodeSelection = { [weak self] in
            self?.presenter.didTapOnCodeSelection()
        }
        self.contactAdditionView.onTapSelection = { [weak self] type in
            self?.presenter.didTapOnSelection(type)
        }
        self.contactAdditionView.onTextUpdate = { [weak self] type, text in
            self?.presenter.save(text: text, for: type)
        }
    }
}

extension ContactAdditionViewController: ContactAdditionViewControllerProtocol {
    func setup(with viewModel: ContactAdditionViewModel) {
        self.contactAdditionView.setup(with: viewModel)
    }

    func set(code: String) {
        self.contactAdditionView.set(code: code)
    }

    func set(contactType: ContactTypeViewModel) {
        self.contactAdditionView.set(contactType: contactType)
    }

    func set(city: City) {
        self.contactAdditionView.set(city: city)
    }

    func set(country: Country) {
        self.contactAdditionView.set(country: country)
    }

    func presentTypeSelection(with controller: UIViewController, scrollView: UIScrollView?) {
        self.selectionPresentationManager.contentViewController = controller
        self.selectionPresentationManager.track(scrollView: scrollView)
        self.selectionPresentationManager.present()
    }

    func showDeleteAlert(type: ContactsListType, completion: @escaping () -> Void) {
        let alert = AlertContollerFactory.makeProfileContactDeletionAlert(type: type, deleteAction: completion)
        self.present(alert, animated: true)
    }

    func showValidationAlert(for field: ContactAdditionFieldType) {
        let alert = UIAlertController(
            title: field.validationText,
            message: "",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        self.present(alert, animated: true)
    }

    func showActivity() {
		self.view.showLoadingIndicator()
    }

    func hideActivity() {
        HUD.find(on: self.view)?.remove(animated: true)
    }
}
