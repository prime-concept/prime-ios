import Foundation

extension Date {
    var customDateTimeString: String {
       string("dd.MM.yy, HH:mm")
    }

    var customDateString: String {
        string("yyyy-MM-dd")
    }

    var birthdayString: String {
        string("dd.MM.yyyy")
    }
}

extension Date {
	static var today: Date {
		Date().down(to: .day)
	}

	var asClosedRange: ClosedRange<Date> {
		self...self
	}

	var asRange: Range<Date> {
		self..<self
	}

	func isIn(same granularity: Calendar.Component, with date: Date) -> Bool {
		Calendar.current.isDate(self, equalTo: date, toGranularity: granularity)
	}

	func down(to granularity: Calendar.Component) -> Date {
		var components = Calendar.Component.roundableCases
		guard let index = components.firstIndex(of: granularity) else {
			fatalError("Only \(components) are permitted!")
		}

		components = Array(components.prefix(through: index))

		let dateComponents = Calendar.current.dateComponents(Set(components), from: self)
		let date = Calendar.current.date(from: dateComponents) ?? self

		return date
	}

	func with(_ component: Calendar.Component, _ value: Int) -> Date? {
		Calendar.current.date(bySetting: component, value: value, of: self)
	}

	subscript (_ component: Calendar.Component) -> Int {
		Calendar.current.component(component, from: self)
	}

	private static let verboseTimeFormat = "YYYY-MM-dd'T'HH:mm:ss"
	private static let tzFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = .current
		formatter.calendar = .current
		formatter.dateFormat = Self.verboseTimeFormat
		return formatter
	}()

	func to(timezone: TimeZone) -> Date {
		Self.tzFormatter.timeZone = timezone

		let nowInRestaurantTimezone = Self.tzFormatter.string(from: self)
		let comparableNow = nowInRestaurantTimezone.date(Self.verboseTimeFormat) ?? self

		return comparableNow
	}

	func to(timezone: String) -> Date {
		guard let timeZone = TimeZone(identifier: timezone) else {
			return self
		}
		return to(timezone: timeZone)
	}
}

extension String {
	func date(_ format: String) -> Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = format
		return formatter.date(from: self)
	}

	func date(_ formats: String...) -> Date? {
		let formatter = DateFormatter()
		for format in formats {
			formatter.dateFormat = format
			if let date = formatter.date(from: self) {
				return date
			}
		}

		return nil
	}
}

extension Date {
	private static let lock = NSLock()
	private static var formattersCache = [String: DateFormatter]()

	func string(_ format: String) -> String {
		Self.lock.lock()
		defer { Self.lock.unlock() }

		if let formatter = Self.formattersCache[format] {
			return formatter.string(from: self)
		}

		let formatter = DateFormatter()
		formatter.dateFormat = format
		Self.formattersCache[format] = formatter

		return formatter.string(from: self)
	}
}

extension ClosedRange where Bound == Date {
	func iterate(by component: Calendar.Component, _ value: Int = 1, _ iterator: (Date) -> Void) {
		var date = self.lowerBound
		while date <= self.upperBound {
			iterator(date)
			guard let newDate = Calendar.current.date(byAdding: component, value: value, to: date) else {
				break
			}
			date = newDate
		}
	}

	func down(to granularity: Calendar.Component) -> Self {
		self.lowerBound.down(to: granularity)...self.upperBound.down(to: granularity)
	}

	static var today: Self {
		Date().down(to: .day).asClosedRange
	}
}

extension Range where Bound == Date {
	func iterate(by component: Calendar.Component, _ value: Int = 1, _ iterator: (Date) -> Void) {
		var date = self.lowerBound
		while date < self.upperBound {
			iterator(date)
			guard let newDate = Calendar.current.date(byAdding: component, value: value, to: date) else {
				break
			}
			date = newDate
		}
	}

	func down(to granularity: Calendar.Component) -> Self {
		self.lowerBound.down(to: granularity)..<self.upperBound.down(to: granularity)
	}

	static var today: Self {
		Date().down(to: .day).asRange
	}
}

extension Array where Element == Date {
	var asRange: ClosedRange<Date> {
		let sorted = self.sorted(by: <)
		return sorted[0]...sorted[sorted.count - 1]
	}
}

extension Calendar.Component {
	public static var allCases: [Calendar.Component] = [
			.weekday,
			.weekdayOrdinal,
			.quarter,
			.weekOfMonth,
			.weekOfYear,
			.yearForWeekOfYear,
			.calendar,
			.timeZone,
			.era,
			.year,
			.month,
			.day,
			.hour,
			.minute,
			.second,
			.nanosecond
	]

	public static var roundableCases: [Self] {
		[
			.year,
			.month,
			.day,
			.hour,
			.minute,
			.second,
			.nanosecond
		]
	}
}

extension Int {
	var hours: DateComponents {
		DateComponents(hour: self)
	}
	var days: DateComponents {
		DateComponents(day: self)
	}
	var months: DateComponents {
		DateComponents(month: self)
	}
	var years: DateComponents {
		DateComponents(year: self)
	}
}

public func +(lhs: Date, rhs: DateComponents) -> Date {
	Calendar.current.date(byAdding: rhs, to: lhs)!
}

extension Optional where Wrapped == Date {
	var or1970: Date {
		self ?? Date(timeIntervalSince1970: 0)
	}
}
