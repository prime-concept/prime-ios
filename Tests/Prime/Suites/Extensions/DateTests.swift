import XCTest
@testable import Prime

final class DateTests: XCTestCase {
	func testStringToDate() {
		let string = "30/07/2023 10:00"
		let formattedDate = string.date("dd/MM/yyyy HH:mm")
		let referenceDate = Calendar.current.date(from: DateComponents(year: 2023, month: 7, day: 30, hour: 10, minute: 0))

		XCTAssertEqual(formattedDate, referenceDate)
	}

	func testDateToString() {
		let date = Calendar.current.date(from: DateComponents(year: 2023, month: 7, day: 30, hour: 10, minute: 0))
		let formattedString = date?.string("dd/MM/yyyy HH:mm")
		let referenceString = "30/07/2023 10:00"

		XCTAssertEqual(formattedString, referenceString)
	}
}
