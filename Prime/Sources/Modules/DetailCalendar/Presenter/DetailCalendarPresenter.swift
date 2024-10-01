import UIKit

protocol DetailCalendarPresenterProtocol {
    func didLoad()
    func openRequest(customID: String)

    func didSelectDate(_ date: Date)
    func didChangePage(_ page: Date)
}

final class DetailCalendarPresenter: DetailCalendarPresenterProtocol {
    private let analyticsReporter: AnalyticsReportingServiceProtocol
    private var events: HomeViewModelEventsMap

	private var selectedDate: Date
    private var selectedPage: Date

	private var tasks = [Task]()

    weak var controller: DetailCalendarViewProtocol?

	@PersistentCodable(fileName: "Home-Feedbacks")
	private var activeFeedbacks = [ActiveFeedback]()

	init(analyticsReporter: AnalyticsReportingServiceProtocol, events: HomeViewModelEventsMap, selectedDate: Date) {
        self.analyticsReporter = analyticsReporter
        self.events = events

		self.selectedDate = selectedDate
        self.selectedPage = selectedDate.down(to: .month)
        
		self.tasks = self.events.values.reduce([CalendarRequestItemViewModel]()){ $0 + $1 }.compactMap(\.task)

		Notification.onReceive(.didUpdateHomeViewModel) { [weak self] notification in
			self?.updateEvents(from: notification)
		}
    }

    func didLoad() {
		self.reloadUI()
    }

    func openRequest(customID: String) {
		let index = self.tasks.firstIndex { $0.customID == customID }
        guard let index = index,
			  let task = self.tasks[safe: index],
			  let controller = self.controller else {
            return
        }

		if task.taskID == Task.aeroticketFlightTaskID {
			self.openAeroflotTicket(task)
			return
		}

		guard  let assistant = task.responsible,
			   let chatParams = ChatAssembly.ChatParameters.make(for: task, assistant: assistant) else {
			return
		}

		var inputDecorations = [UIView]()
		let feedback = self.activeFeedbacks.first { $0.objectId == task.taskID.description }
		if let feedback {
			inputDecorations.append(
				DefaultRequestItemFeedbackView.standalone(taskId: task.taskID, insets: [0, 5, 0, 0]) { [weak self] in
					guard let self else { return }
					self.analyticsReporter.didTapOnFeedbackInChat(taskId: task.taskID, feedbackGuid: feedback.guid^)
				}
			)
		}

        let chatViewControler = ChatAssembly.makeChatContainerViewController(
            with: chatParams,
			inputDecorationViews: inputDecorations
        )

        let router = ModalRouter(
            source: controller,
            destination: chatViewControler,
            modalPresentationStyle: .pageSheet
        )
        router.route()
        self.analyticsReporter.tappedEventInCalendar(mode: .expanded)
    }

    func didSelectDate(_ date: Date) {
        let dateChanged = selectedDate.down(to: .day) != date.down(to: .day)
        selectedDate = date
        reloadUI(changingSelectedDate: dateChanged)
    }

    func didChangePage(_ page: Date) {
        selectedPage = page.down(to: .month)
    }

	private func openAeroflotTicket(_ task: Task) {
		guard let userInfo = task.events.first?.userInfo else {
			return
		}

		let ticket = userInfo["ticket"] as? Aerotickets.Ticket
		let flight = userInfo["flight"] as? Aerotickets.Flight

		guard let ticket, let flight else { return }

		let vc = AeroticketAssembly(ticket: ticket, flight: flight).make()
		self.controller?.topmostPresentedOrSelf.present(vc, animated: true)
	}

	private func reloadUI(changingSelectedDate: Bool = true) {
		let daysSorted = Array(self.events.allDays).sorted(by: <)
		let eventsSorted: [CalendarViewModel.CalendarItem] = daysSorted.compactMap { date in
			guard let events = self.events[date] else {
				return nil
			}
			return CalendarViewModel.CalendarItem(date: date, tasks: events)
		}

		var viewModel = CalendarViewModel(
			currentPage: self.selectedPage,
			selectedDates: self.selectedDate...self.selectedDate,
            items: eventsSorted
		)

		viewModel.shouldScrollItemsToTop = changingSelectedDate

		self.controller?.update(with: viewModel)
	}

	private func updateEvents(from notification: Notification) {
		let viewModel = notification.userInfo?["viewModel"] as? HomeViewModel
		let events = viewModel?.eventsByDays
		
		guard let events else { return }

		self.events = events
		self.tasks = self.events.values.reduce([CalendarRequestItemViewModel]()){ $0 + $1 }.compactMap(\.task)

		self.reloadUI(changingSelectedDate: false)
	}
}
