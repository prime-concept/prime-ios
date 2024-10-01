import UIKit
import XLPagerTabStrip

protocol ContactsListViewControllerProtocol: ModalRouterSourceProtocol {
    func setup(with viewModel: ContactsListViewModel)
}

final class ContactsListViewController: UIViewController {
    private lazy var contactsListView = ContactsListView()

    private let presenter: ContactsListPresenterProtocol
    private let tabTitle: String
    private let shouldOpenInCreationMode: Bool

    init(presenter: ContactsListPresenterProtocol, title: String, shouldOpenInCreationMode: Bool = false) {
        self.presenter = presenter
        self.tabTitle = title
        self.shouldOpenInCreationMode = shouldOpenInCreationMode

        super.init(nibName: nil, bundle: nil)

		self.title = title
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override var preferredStatusBarStyle: UIStatusBarStyle {
		.lightContent
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupList()
        self.presenter.didLoad()
        delay(1) {
            self.shouldOpenInCreationMode ? (self.presenter.didTapOnAddContact()) : (nil)
        }
    }
    // MARK: - Helpers

    private func setupList() {
        self.view.addSubview(self.contactsListView)
        self.contactsListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.contactsListView.onTapAdd = { [weak self] in
            self?.presenter.didTapOnAddContact()
        }
        self.contactsListView.onSelect = { [weak self] id in
            self?.presenter.didTapOnContact(with: id)
        }
    }
}

extension ContactsListViewController: ContactsListViewControllerProtocol {
    func setup(with viewModel: ContactsListViewModel) {
        self.contactsListView.setup(with: viewModel)
    }
}

extension ContactsListViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: self.tabTitle)
    }
}
