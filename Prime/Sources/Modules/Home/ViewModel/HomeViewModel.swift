import UIKit
import ChatSDK

struct HomeViewModel {
	let requestsListHeader: RequestListHeaderViewModel
	let banners: [HomeBannerViewModel]
	let requests: [RequestListItemViewModel]
	let paymentItems: [HomePayItemViewModel]
	let calendarItems: [HomeCalendarItemViewModel]
	var eventsByDays: HomeViewModelEventsMap
	let generalChatUnreadMessagesCount: Int

	init(
		allTasks: [Task],
		activeTasks: [Task],
		displayableTasks: [Task],
		aerotickets: Aerotickets,
		banners: [HomeBannerViewModel],
		feedbacks: [ActiveFeedback],
        promoCategories: [Int: [Int]],
		generalChatUnreadMessagesCount: Int
	) {
		let feedbackIds = feedbacks.map { $0.objectId }

		self.requests = displayableTasks.map {
			let showsFeedback = feedbackIds.contains($0.taskID.description)
            return RequestListItemViewModel(task: $0, showsFeedback: showsFeedback, promoCategories: promoCategories)
		}

		self.banners = banners
		self.eventsByDays = Self.groupEventsByDays(from: allTasks, tickets: aerotickets)
		self.calendarItems = Self.makeCalendarItems(from: self.eventsByDays)
		self.paymentItems = Self.makePaymentItems(from: activeTasks)
		self.requestsListHeader = Self.makeRequestListHeader(
			allTasks: allTasks,
			activeTasks: activeTasks,
			displayableTasks: displayableTasks
		)
        self.generalChatUnreadMessagesCount = generalChatUnreadMessagesCount
	}
    	
	private static func makeRequestListHeader(
		allTasks: [Task],
		activeTasks: [Task],
		displayableTasks: [Task]
	) -> RequestListHeaderViewModel {
		let activeCount = activeTasks.count
		let completedCount = max(0, allTasks.count - activeCount)

		let requestHeader = RequestListHeaderViewModel(
			activeCount: activeCount,
			completedCount: completedCount,
			mayShowCreateNewRequestButton: !displayableTasks.isEmpty,
			latestMessageViewModel: nil
		)

		return requestHeader
	}

	private static func makePaymentItems(from tasks: [Task]) -> [HomePayItemViewModel] {
		let orderMaker: (Task) -> [HomePayItemViewModel] = { task in
			let taskIcon = task.taskType?.image
			let filteredOrders = task.ordersWaitingForPayment
			return filteredOrders.map { HomePayItemViewModel(order: $0, taskIcon: taskIcon) }
		}

		return tasks.flatMap(orderMaker)
	}

	private static func groupEventsByDays(
		from tasks: [Task],
		tickets: Aerotickets
	) -> HomeViewModelEventsMap {
 		var eventsMap = HomeViewModelEventsMap()

		let ticketEvents = tickets.events()
		let aeroticketsTasksIDs = tickets.result?.compactMap(\.taskId) ?? []

		let taskEvents: [CalendarEvent] = tasks.flatMap { task in
			let events: [CalendarEvent] = task.events^.compactMap { event in
				var isAvia = event.taskTypeId == TaskTypeEnumeration.avia.id
				isAvia |= event.taskTypeId == TaskTypeEnumeration.aeroflotAvia.id

				if isAvia, aeroticketsTasksIDs.contains(event.taskId) {
					return nil
				}

				var event = event
				event.task = task
				return event
			}

			return events
		}

		let events = taskEvents + ticketEvents

		for event in events {
			guard let date = event.startDateDay else {
				continue
			}

			let startDateFormatted = formatStartDate(
				date: event.startDateDate,
				allDay: event.allDay
			)

			// Вот тут генерятся мелкие модели для Маленького Календаря на Главной
			// для горизонтальной крутилки мелких событий
			var eventsForDate = eventsMap[date] ?? []
			eventsForDate.append(
				CalendarRequestItemViewModel(
					task: event.task,
					title: event.title,
					subtitle: startDateFormatted,
					location: event.location,
					logo: event.taskTypeImage,
					hasReservation: event.hasReservation,
					date: event.startDateDay ?? date,
					formattedDate: event.displayableDate
				)
			)
			eventsMap[date] = eventsForDate
		}
		return eventsMap
	}
    
	private static func formatStartDate(date: Date?, allDay: Bool) -> String {
        guard let date = date else {
            return ""
        }
		var abbreviation: String

        if Calendar.current.isDateInToday(date) {
			abbreviation = "smallCalendar.today".localized
        } else if Calendar.current.isDateInTomorrow(date) {
			abbreviation = "smallCalendar.tomorrow".localized
		} else {
			return date.string("dd.MM.yy, HH:mm")
		}

		if allDay {
			return abbreviation + ", " + "smallCalendar.allDay".localized
		}

		let hhmm = date.string("HH:mm")
		if !hhmm.isEmpty {
			abbreviation = abbreviation + ", " + hhmm
		}

		return abbreviation
    }
    
	private static func makeCalendarItems(from eventsMap: HomeViewModelEventsMap) -> [HomeCalendarItemViewModel] {
		let today = Date().down(to: .day)
		var datesSorted = Array(eventsMap.allDays)
		datesSorted.append(today + 14.days)
		datesSorted.sort(by: <)

		let oldestDate = today + (-1).days
		let newestDate = datesSorted.last!

		let daysElapsed = Int(newestDate.timeIntervalSince(oldestDate)) / 60 / 60 / 24
        let days: [Date] = (0...daysElapsed).map { i in
            oldestDate + i.days
		}

		let calendarItems: [HomeCalendarItemViewModel] = days.map { date in
			let tasksByDate = eventsMap[date] ?? []

			return HomeCalendarItemViewModel(
				dayItemViewModel: Self.makeCalendarDayItemViewModel(
					from: date,
					hasEvents: !tasksByDate.isEmpty
				),
				items: tasksByDate
			)
		}
		
		return calendarItems
	}

	private static var datesToModels: [Date: CalendarDayItemViewModel] = [:]

	private static func makeCalendarDayItemViewModel(from date: Date, hasEvents: Bool) -> CalendarDayItemViewModel {
		if var model = Self.datesToModels[date] {
			model.hasEvents = hasEvents
			return model
		}

		let calendar = Calendar.current

		let day = calendar.component(.day, from: date)
		let weekdayNumber = calendar.component(.weekday, from: date)
		let month = calendar.component(.month, from: date)

		// Удивительно, но тормозят Symbols!
		let model = CalendarDayItemViewModel(
			dayOfWeek: calendar.shortWeekdaySymbols[weekdayNumber - 1],
			dayNumber: "\(day)",
			month: calendar.shortMonthSymbols[month - 1],
			hasEvents: hasEvents,
			date: date
		)

		Self.datesToModels[date] = model

		return model
	}
}

struct HomeViewModelEventsMap {
    private let dateFormat = "yyyy-MM-dd"
    private var data = [String: [CalendarRequestItemViewModel]]()

    var allDays: [Date] {
        data.keys.compactMap { $0.date(dateFormat) }
    }

    var values: [[CalendarRequestItemViewModel]] {
        Array(data.values)
    }

    subscript(day: Date) -> [CalendarRequestItemViewModel]? {
        get {
            data[day.string(dateFormat)]
        }
        set {
            data[day.string(dateFormat)] = newValue
        }
    }
}
