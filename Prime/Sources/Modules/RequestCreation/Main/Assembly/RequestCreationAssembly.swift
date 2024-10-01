import UIKit
import ChatSDK

final class RequestCreationAssembly: Assembly {
	private let preinstalledText: String?

	init(preinstalledText: String?) {
		self.preinstalledText = preinstalledText
	}

    func make() -> UIViewController {
        let presenter = RequestCreationPresenter(
			preinstalledText: self.preinstalledText,
			taskPersistenceService: TaskPersistenceService.shared,
            profileService: ProfileService.shared,
			graphQLEndpoint: GraphQLEndpoint(),
			servicesEndpoint: ServicesEndpoint.makeInstance(),
            analyticsReporter: AnalyticsReportingService()
        )
        let controller = RequestCreationViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
