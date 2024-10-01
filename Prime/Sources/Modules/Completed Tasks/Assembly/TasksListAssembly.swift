import UIKit

final class TasksListAssembly: Assembly {
    private let type: TasksListType

    init(type: TasksListType) {
        self.type = type
    }

    func make() -> UIViewController {
        let presenter = TasksListPresenter(
			taskPersistenceService: TaskPersistenceService.shared,
            analyticsReporter: AnalyticsReportingService(),
            tasksListType: self.type
        )
        let controller = TasksListViewController(
            presenter: presenter,
            title: Localization.localize(self.type.rawValue)
        )
        presenter.controller = controller
        return controller
    }
}
