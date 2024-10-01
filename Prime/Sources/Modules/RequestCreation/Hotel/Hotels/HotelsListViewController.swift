import UIKit

protocol HotelsListViewControllerProtocol: ModalRouterSourceProtocol {
    func set(list: HotelsListViewModel)
}

final class HotelsListViewController: UIViewController {
    private lazy var hotelsListView = self.view as? HotelsListView

    private let presenter: HotelsListPresenterProtocol

    init(presenter: HotelsListPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        self.view = HotelsListView()
        let grabber = GrabberView()
        self.view.addSubview(grabber)
        grabber.make(.edges(except: .bottom), .equalToSuperview)
        grabber.make(.height, .equal, 14)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.setupActions()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let tap = UITapGestureRecognizer(
            target: self.view,
            action: #selector(UIView.endEditing)
        )
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    private func setupActions() {
        self.hotelsListView?.onHotelSelected = { [weak self] id in
            self?.presenter.didSelectHotel(with: id)
            self?.dismiss(animated: true, completion: nil)
        }
        self.hotelsListView?.onCitySelected = { [weak self] id in
            self?.presenter.didSelectCity(with: id)
            self?.dismiss(animated: true, completion: nil)
        }
        self.hotelsListView?.onSearchQueryChanged = { [weak self] query in
            self?.presenter.search(by: query)
        }
        
        self.hotelsListView?.onFilterCategorySelected = { [weak self] categoryType in
            self?.presenter.didSelectCategoryFilter(type: categoryType)
        }
    }
}

extension HotelsListViewController: HotelsListViewControllerProtocol {
    func set(list: HotelsListViewModel) {
        self.hotelsListView?.setup(with: list)
    }
}
