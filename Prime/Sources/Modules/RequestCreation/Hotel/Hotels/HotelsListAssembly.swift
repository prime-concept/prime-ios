import UIKit

final class HotelsListAssembly: Assembly {
    private var onSelect: (Hotel?, HotelCity?) -> Void

    init(onSelect: @escaping (Hotel?, HotelCity?) -> Void) {
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = HotelsListPresenter(
            onSelect: self.onSelect,
            graphQLEndpoint: GraphQLEndpoint(),
            analyticsRepoter: AnalyticsReportingService()
        )
        let controller = HotelsListViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
