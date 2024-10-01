import Foundation

final class PrimeDateFormatter {
	private static let defaultDateFormat: String = "dd.MM.yy"

	@PersistentCodable(fileName: "PrimeDateFormatter.datesCache", async: false)
	private static var datesCache = [String: Date?]()

    static func serverDate(from string: String) -> Date? {
		if let date = self.datesCache[string] {
			return date
		}

		let date = string.date(
			"yyyy-MM-dd'T'HH:mm:ss.SZ",
			"yyyy-MM-dd HH:mm:ss.SZ",
			"yyyy-MM-dd'T'HH:mm:ss.S",
			"yyyy-MM-dd HH:mm:ss.S",
			"yyyy-MM-dd'T'HH:mm:ss",
			"yyyy-MM-dd HH:mm:ss",
			"\(defaultDateFormat) HH:mm"
		)

		self.datesCache[string] = date

		return date
    }

	private static let olderMessageDateTimeCacheLock = NSLock()

	@PersistentCodable(fileName: "PrimeDateFormatter.olderMessageDateTimeCache", async: false)
	private static var olderMessageDateTimeCache = [Date: String]()

	private static let todayMessageTimeFormatter = with(DateFormatter()) {
		$0.calendar = Calendar.current
		$0.locale = Locale.current
		$0.dateFormat = "HH:mm"
	}

	private static let weekMessageTimeFormatter = with(DateFormatter()) {
		$0.calendar = Calendar.current
		$0.locale = Locale.current
		$0.dateFormat = "E"
	}

	private static let olderMessageTimeFormatter = with(DateFormatter()) {
		$0.calendar = Calendar.current
		$0.locale = Locale.current
		$0.dateFormat = "\(defaultDateFormat)"
	}

    static func messageDateTimeString(from date: Date) -> String? {
		let today = Date().down(to: .day)
		let weekAgo = today + (-7).days

		if date >= today {
			return todayMessageTimeFormatter.string(from: date)
		} else if date >= weekAgo {
			return weekMessageTimeFormatter.string(from: date)
		}

		if let cached = self.olderMessageDateTimeCache[date] {
			return cached
		}

		olderMessageDateTimeCacheLock.lock()
		let result = self.olderMessageTimeFormatter.string(from: date)
		olderMessageDateTimeCache[date] = result
		olderMessageDateTimeCacheLock.unlock()

		return result
    }

	private static let calendarTimeFormatter = with(DateFormatter()) { formatter in
		let formatter = DateFormatter()
		formatter.calendar = Calendar.current
		formatter.locale = Locale.current
		formatter.dateFormat = "LLLL yyyy"
	}

    static func calendarTimeString(from date: Date) -> String {
		Self.calendarTimeFormatter.string(from: date)
    }

	private static let longOrderTimeFormatter = with(DateFormatter()) { formatter in
		formatter.calendar = Calendar.current
		formatter.locale = Locale.current
		formatter.dateFormat = "dd.MM"
	}

    static func longOrderTimeString(from date: Date) -> String {
		Self.longOrderTimeFormatter.string(from: date)
    }

	private static let shortOrderTimeFormatter = with(DateFormatter()) { formatter in
		formatter.dateFormat = "HH:mm"
	}

    static func shortOrderTimeString(from date: Date) -> String {
		Self.shortOrderTimeFormatter.string(from: date)
    }
}

extension String {
	var serverDate: Date? {
		PrimeDateFormatter.serverDate(from: self)
	}
}
