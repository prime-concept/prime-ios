import UIKit

final class AirportListAssembly: Assembly {
    private let leg: FlightLeg
    private let mayTapOnCityHub: Bool
    private var onSelect: (Airport) -> Bool
	private(set) var scrollView: UIScrollView?

    init(
        leg: FlightLeg,
        mayTapOnCityHub: Bool = false,
        onSelect: @escaping (Airport) -> Bool
    ) {
        self.leg = leg
        self.mayTapOnCityHub = mayTapOnCityHub
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = AirportListPresenter(
            leg: self.leg,
            mayTapOnCityHub: self.mayTapOnCityHub,
            onSelect: self.onSelect,
            graphQLEndpoint: GraphQLEndpoint(),
			airportPersistenceService: AirportPersistenceService.shared,
			airportSearchService: AirportSearchService(locationService: LocationService.shared)
        )
        let controller = AirportListViewController(presenter: presenter)
        presenter.controller = controller
		self.scrollView = controller.scrollView
        return controller
    }
}
