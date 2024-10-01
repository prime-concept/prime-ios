import UIKit

protocol AirportListViewProtocol: AnyObject {
    func set(viewModel: AirportListsViewModel)
}

extension AirportListViewController {
    struct Appearance: Codable {
        var collectionBackground = Palette.shared.gray5
        var collectionItemSize = CGSize(width: UIScreen.main.bounds.width, height: 55)

        var clearBackgroundColor = Palette.shared.gray5
        var clearFont = Palette.shared.primeFont.with(size: 16)
        var clearTextColor = Palette.shared.gray0
        var clearBorderWidth: CGFloat = 0.5
        var clearBorderColor = Palette.shared.gray3

        var applyBackgroundColor = Palette.shared.brandPrimary
        var applyFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
        var applyTextColor = Palette.shared.gray5

        var buttonCornerRadius: CGFloat = 8
    }

	var scrollView: UIScrollView? {
		self.airportListView?.scrollView
	}
}

final class AirportListViewController: UIViewController, AirportListViewProtocol {
    private lazy var airportListView = self.view as? AirportListView

    private let presenter: AirportListPresenterProtocol
    private let appearance: Appearance

    init(presenter: AirportListPresenterProtocol, appearance: Appearance = Theme.shared.appearance()) {
        self.presenter = presenter
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        self.view = AirportListView()
		let grabber = GrabberView()
		self.view.addSubview(grabber)
		grabber.make(.edges(except: .bottom), .equalToSuperview)
		grabber.make(.height, .equal, 14)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        airportListView?.onAirportSelected = { [weak self] selection in
            let selected = self?.presenter.didSelectAirport(selection) ?? true
			if selected {
				self?.dismiss(animated: true, completion: nil)
			}
        }
        airportListView?.onSearchQueryChanged = { [weak self] query in
            self?.presenter.setQuery(query: query)
        }

        self.presenter.didLoad()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: AirportListsViewModel) {
        airportListView?.setup(with: viewModel)
    }
}
