protocol AviaRouteSelectionPresenterProtocol: CatalogItemSelectionPresenterProtocol {
    var title: String { get }
}

final class AviaRouteSelectionPresenter: AviaRouteSelectionPresenterProtocol {
    private var data: [AviaRouteViewModel] = []

    weak var controller: AviaRouteSelectionViewController?

    let preselectedRoute: AviaRoute
    var onSelect: (AviaRoute) -> Void

    init(preselectedRoute: AviaRoute, onSelect: @escaping (AviaRoute) -> Void) {
        self.preselectedRoute = preselectedRoute
        self.onSelect = onSelect
    }

    // MARK: - AviaRouteSelectionPresenterProtocol

    var title: String {
        "avia.route".localized
    }

    func didLoad() {
        self.data = AviaRoute.allCases.map { route in
            let isSelected = route == self.preselectedRoute
            return AviaRouteViewModel(route: route, isSelected: isSelected)
        }
    }

    func search(by string: String) {}

    func numberOfItems() -> Int {
        self.data.count
    }

    func item(at index: Int) -> CatalogItemRepresentable {
        self.data[index]
    }

    func select(at index: Int) {
        let selectedRouteViewModel = self.data[index]
        if let previouslySelectedIndex = self.data.firstIndex(where: { $0.selected }) {
            self.data[previouslySelectedIndex].selected = false
        }
        self.data[index].selected = true
        self.controller?.reload()
        self.onSelect(selectedRouteViewModel.route)
    }

    func apply() {}
}
