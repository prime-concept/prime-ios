import Foundation
import FSCalendar

struct CalendarViewModel {
	struct CalendarItem {
		let date: Date
		let tasks: [CalendarRequestItemViewModel]
	}

	let scope: FSCalendarScope
	let items: [CalendarItem]

    let currentPage: Date
	let selectedDates: ClosedRange<Date>?

	var shouldScrollItemsToTop = true

	let isScopeSelectionEnabled: Bool
	let isMultipleSelectionAllowed: Bool

	init(
		scope: FSCalendarScope = .month,
		currentPage: Date = Date(),
        selectedDates: ClosedRange<Date>?,
		items: [CalendarViewModel.CalendarItem] = [],
		isScopeSelectionEnabled: Bool = true,
		isMultipleSelectionAllowed: Bool = false
	) {
		self.scope = scope
		self.currentPage = currentPage
		self.selectedDates = selectedDates
		self.items = items
		self.isScopeSelectionEnabled = isScopeSelectionEnabled
		self.isMultipleSelectionAllowed = isMultipleSelectionAllowed
	}
}
