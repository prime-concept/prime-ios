import XCTest
@testable import Prime

final class CollectionsUtilsTests: XCTestCase {
	func testSplitMinus1() throws {
		let array = [1, 2, 3]
		let result = array.split(by: -1)
		XCTAssertEqual(result, [[1], [2], [3]])
	}

	func testSplit0() throws {
		let array = [1, 2, 3]
		let result = array.split(by: 0)
		XCTAssertEqual(result, [[1], [2], [3]])
	}

	func testSplit1() throws {
		let array = [1, 2, 3]
		let result = array.split(by: 1)
		XCTAssertEqual(result, [[1], [2], [3]])
	}

	func testSplit2() throws {
		let array = [1, 2, 3]
		let result = array.split(by: 2)
		XCTAssertEqual(result, [[1, 2], [3]])
	}

	func testSplit2_4() throws {
		let array = [1, 2, 3, 4]
		let result = array.split(by: 2)
		XCTAssertEqual(result, [[1, 2], [3, 4]])
	}

	func testSplit3() throws {
		let array = [1, 2, 3]
		let result = array.split(by: 3)
		XCTAssertEqual(result, [[1, 2, 3]])
	}

	func testSplit4() throws {
		let array = [1, 2, 3]
		let result = array.split(by: 4)
		XCTAssertEqual(result, [[1, 2, 3]])
	}
}
