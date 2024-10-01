import UIKit

final class OnboardingAssembly: Assembly {
    private let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func make() -> UIViewController {
        let presenter = OnboardingPresenter(
			onboardingService: OnboardingService(
                locationService: LocationService.shared,
                analyticsReporter: AnalyticsReportingService()
            ),
            completion: self.completion
        )
        let controller = OnboardingViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
