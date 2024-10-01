import UIKit

final class AviaFormAssembly {
    func make() -> AviaFormViewControllerProtocol {
        let presenter = AviaFormPresenter(
            graphQLEndpoint: GraphQLEndpoint(),
            localAuthService: LocalAuthService.shared,
            analyticsReporter: AnalyticsReportingService()
        )
        let controller = AviaFormViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
