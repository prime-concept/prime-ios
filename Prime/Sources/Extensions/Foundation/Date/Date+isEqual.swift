import Foundation

extension Date {
    func isEqual(with date: Date) -> Bool {
        Calendar.current.startOfDay(for: self) == Calendar.current.startOfDay(for: date)
    }
}
