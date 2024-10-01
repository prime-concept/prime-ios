@testable import Prime
import XCTest

final class OptionalConvenienceTests: XCTestCase {

	func testQQAssignmentLhsNilRhsSomeYieldsLhsSome() {
        var lhs: String?
		lhs ??= "some"
		XCTAssertEqual(lhs, "some")
	}

	func testQQAssignmentLhsSomeRhsNilYieldsLhsSome() {
		var lhs: String? = "some"
		lhs ??= nil
		XCTAssertEqual(lhs, "some")
	}

	func testQQAssignmentLhsSome1RhsSome2YieldsLhsSome1() {
		var lhs: String? = "some1"
		lhs ??= "some2"
		XCTAssertEqual(lhs, "some1")
	}

	func testQQAssignmentLhsNilRhsNilYieldsLhsNil() {
        var lhs: String?
		lhs ??= nil
		XCTAssertNil(lhs)
	}

}
