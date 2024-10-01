import UIKit

final class SMSCodeAssembly: Assembly {
    private let phone: String
    private var onLoginProblems: () -> Void

    init(phone: String, onLoginProblems: @escaping () -> Void) {
        self.phone = phone
        self.onLoginProblems = onLoginProblems
    }

    func make() -> UIViewController {
        let presenter = SMSCodePresenter(
            endpoint: AuthEndpoint(),
            phone: self.phone,
            authService: .shared,
            analyticsReporter: AnalyticsReportingService(),
			onLoginProblems: self.onLoginProblems
        )

        let controller = SMSCodeViewController(presenter: presenter)
		UIView.performWithoutAnimation {
			controller.view.frame = UIScreen.main.bounds
			controller.view.setNeedsLayout()
			controller.view.layoutIfNeeded()
		}

        presenter.controller = controller

        return controller
    }
}
