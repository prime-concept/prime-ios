import Foundation

struct HomeCalendarItemViewModel: Equatable {
    let dayItemViewModel: CalendarDayItemViewModel
    let items: [CalendarRequestItemViewModel]
}

struct HomeCalendarItemCellViewModel {
    let dayItemViewModel: CalendarDayItemViewModel
    let item: CalendarRequestItemViewModel
}
