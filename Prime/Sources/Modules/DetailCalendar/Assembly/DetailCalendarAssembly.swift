import UIKit

final class DetailCalendarAssembly: Assembly {
    private var events: HomeViewModelEventsMap
	private let date: Date
    private weak var transitioningDelegate: UIViewControllerTransitioningDelegate?

	init(transitioningDelegate: UIViewControllerTransitioningDelegate?, events: HomeViewModelEventsMap, date: Date) {
        self.transitioningDelegate = transitioningDelegate
        self.events = events
		self.date = date
    }

    func make() -> UIViewController {
		let presenter = DetailCalendarPresenter(
            analyticsReporter: AnalyticsReportingService(),
            events: self.events,
			selectedDate: self.date
        )
		let controller = DetailCalendarViewController(presenter: presenter, date: self.date)
        controller.transitioningDelegate = self.transitioningDelegate
        presenter.controller = controller
        return controller
    }
}
