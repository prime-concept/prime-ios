import Foundation

struct CalendarDayItemViewModel: Equatable {
    var dayOfWeek: String
    var dayNumber: String
    var month: String
    var hasEvents: Bool
    var date: Date

    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self.date)
    }

    static var mockData: [CalendarDayItemViewModel] {
        var days: [CalendarDayItemViewModel] = []
        let calendar = Calendar.current
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        )
        if let startOfWeek = startOfWeek {
            let week = (0...6).compactMap {
                Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek)
            }

            for date in week {
                let day = calendar.component(.day, from: date)
                let weekdayNumber = calendar.component(.weekday, from: date)
                let month = calendar.component(.month, from: date)

                days.append(
                    CalendarDayItemViewModel(
                        dayOfWeek: calendar.shortWeekdaySymbols[weekdayNumber - 1],
                        dayNumber: "\(day)",
                        month: calendar.shortMonthSymbols[month - 1],
                        hasEvents: arc4random_uniform(2) == 0,
                        date: date
                    )
                )
            }
        }
        return days
    }
}
