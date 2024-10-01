import UIKit

final class AviaRouteSelectionAssembly: Assembly {
    let preselectedRoute: AviaRoute
    let onSelect: (AviaRoute) -> Void

    init(preselectedRoute: AviaRoute, onSelect: @escaping (AviaRoute) -> Void) {
        self.preselectedRoute = preselectedRoute
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = AviaRouteSelectionPresenter(
            preselectedRoute: self.preselectedRoute,
            onSelect: self.onSelect
        )
        let controller = AviaRouteSelectionViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
