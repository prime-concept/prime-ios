import Foundation

extension Date {
    init?(string: String?) {
        if let unwrappedString = string, let date = PrimeDateFormatter.serverDate(from: unwrappedString) {
            self = date
        } else {
            return nil
        }
    }

    var noon: Date {
        // swiftlint:disable:next force_unwrapping
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
}
