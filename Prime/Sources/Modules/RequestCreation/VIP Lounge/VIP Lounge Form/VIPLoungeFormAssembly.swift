import UIKit

final class VIPLoungeFormAssembly {
    func make() -> VIPLoungeFormViewControllerProtocol {
        let presenter = VIPLoungeFormPresenter(
            graphQLEndpoint: GraphQLEndpoint(),
            analyticsReporter: AnalyticsReportingService(),
            localAuthService: LocalAuthService.shared,
            airportPersistenceService: AirportPersistenceService.shared,
            airportSearchService: AirportSearchService(locationService: LocationService.shared)
        )
        let controller = VIPLoungeFormViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
