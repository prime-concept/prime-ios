import UIKit

final class HomeAssembly: Assembly {
	private let onDidLoad: ((UIViewController) -> Void)

	init(onDidLoad: @escaping ((UIViewController) -> Void)) {
		self.onDidLoad = onDidLoad
	}

    func make() -> UIViewController {
        let analyticsRepoter = AnalyticsReportingService()
        let authService = LocalAuthService()
        let taskManager = HomeTaskManager()
        let feedbackManager = HomeFeedbackManager()

        let controller = HomeViewController()
        let router = HomeRouter(
            viewController: controller,
            analyticsReporter: analyticsRepoter,
            deeplinkService: DeeplinkService.shared
        )
        let presenter = HomePresenter(
            controller: controller,
            router: router,
            taskManager: taskManager, 
            feedbackManager: feedbackManager,
            graphQLEndpoint: GraphQLEndpoint(),
			taskPersistenceService: TaskPersistenceService.shared,
            localAuthService: authService,
			calendarService: CalendarEventsService.shared,
			profileService: ProfileService.shared,
            deeplinkService: DeeplinkService.shared,
            analyticsRepoter: analyticsRepoter,
			fileService: FilesService.shared,
			servicesEndpoint: ServicesEndpoint.makeInstance(),
            onDidLoad: self.onDidLoad
        )
        taskManager.delegate = presenter
        feedbackManager.delegate = taskManager
        controller.presenter = presenter
        controller.router = router
        router.delegate = presenter
		
		let navigationController = NavigationController(
			rootViewController: controller,
			navigationBarClass: CrutchyNavigationBar.self
		)
		
		navigationController.view.frame = UIScreen.main.bounds

		return navigationController
    }
}
