import UIKit

final class ApplicationContainerAssembly: Assembly {
    func make() -> UIViewController {
        let presenter = ApplicationContainerPresenter(
            authService: .shared,
            onboardingService: OnboardingService(),
			taskPersistenceService: TaskPersistenceService.shared,
            analyticsService: AnalyticsService(),
            analyticsReporter: AnalyticsReportingService(),
            defaultsService: DefaultsService.shared,
            endpoint: AuthEndpoint()
        )
        let controller = ApplicationContainerViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
