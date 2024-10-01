import PassKit
import UIKit
import XLPagerTabStrip

protocol ProfileViewControllerProtocol: UIViewController {
    func setup(with viewModel: ProfileViewModel)
    func presentDocuments(index: Int, shouldOpenInCreationMode: Bool)
    func presentCards(index: Int, shouldOpenInCreationMode: Bool)
    func presentContacts(index: Int, shouldOpenInCreationMode: Bool)
    func presentFamily(index: Int, shouldOpenInCreationMode: Bool)
    func didTapOnMeSection(index: Int, shouldOpenInCreationMode: Bool)
    
	func showLoading()
	func hideLoading()

    func presentPKPassAddition(with pass: PKPass)
    func setAddToWalletButton(hidden: Bool)
    func setAddedToWalletView(hidden: Bool)
}

final class ProfileViewController: UIViewController {
	private var profileFetchedSuccessfully = false

    private lazy var profileView: ProfileView = {
        let view = ProfileView(onSelect: { type in
			self.presenter.didSelect(type)
		})
        return view
    }()

	private var loaderIsShown = false
    private let presenter: ProfilePresenterProtocol
    private let tabTitle: String

    init(presenter: ProfilePresenterProtocol, title: String) {
        self.presenter = presenter
        self.tabTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupList()
        self.presenter.fetchProfileIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.checkForUpdates),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        self.checkForUpdates()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

        self.presenter.didAppear()

		if self.loaderIsShown || !self.profileFetchedSuccessfully {
			self.hideLoading()
			self.showLoading()
		}
	}

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: - Helpers

    private func setupList() {
        self.view.addSubview(self.profileView)
        self.profileView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    private func checkForUpdates() {
		self.presenter.fetchProfileIfNeeded()
        self.presenter.updateWalletPassKitControlsIfPossible()
    }
}

extension ProfileViewController: ProfileViewControllerProtocol {
    func setup(with viewModel: ProfileViewModel) {
		self.profileFetchedSuccessfully = viewModel.loadingSucceeded
        self.profileView.setup(with: viewModel)
    }

    func presentDocuments(index: Int, shouldOpenInCreationMode: Bool) {
        let controller = DocumentsAssembly(
            indexToMove: index,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        ).make()
        let router = PushRouter(source: self, destination: controller)
        router.route()
    }

    func presentContacts(index: Int, shouldOpenInCreationMode: Bool) {
        let controller = ContactsAssembly(
            indexToMove: index,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        ).make()
        let router = PushRouter(source: self, destination: controller)
        router.route()

    }

    func presentCards(index: Int, shouldOpenInCreationMode: Bool) {
        let controller = CardsAssembly(
            indexToMove: index,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        ).make()
        let router = PushRouter(source: self, destination: controller)
        router.route()
    }

    func presentFamily(index: Int, shouldOpenInCreationMode: Bool) {
        let controller = PersonsAssembly(
            indexToMove: index,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        ).make()
        let router = PushRouter(source: self, destination: controller)
        router.route()
    }
    
    func didTapOnMeSection(index: Int, shouldOpenInCreationMode: Bool) {
        switch index {
        case 0:
            self.presentContacts(index: 0, shouldOpenInCreationMode: shouldOpenInCreationMode)
        case 1:
            self.presentFamily(index: 0, shouldOpenInCreationMode: shouldOpenInCreationMode)
        case 2:
            self.presentDocuments(index: 0, shouldOpenInCreationMode: shouldOpenInCreationMode)
        default:
            break
        }
    }

	func showLoading() {
		if self.profileFetchedSuccessfully {
			return
		}

		self.profileView.alpha = 0.7
		self.loaderIsShown = true
		self.showLoadingIndicator(needsPad: true)
	}

	func hideLoading() {
		self.loaderIsShown = false
		self.profileView.alpha = 1
		self.hideLoadingIndicator()
	}

    func presentPKPassAddition(with pass: PKPass) {
        guard let controller = PKAddPassesViewController(pass: pass) else {
            return
        }
        controller.delegate = self
        self.present(controller, animated: true)
    }
}

extension ProfileViewController: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true)
        self.presenter.updateWalletPassKitControlsIfPossible()
    }

    func setAddToWalletButton(hidden: Bool) {
        self.profileView.setAddToWalletButton(hidden: hidden)
    }

    func setAddedToWalletView(hidden: Bool) {
        self.profileView.setAddedToWalletView(hidden: hidden)
    }
}

extension ProfileViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: self.tabTitle)
    }
}
