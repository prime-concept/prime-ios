import XCTest
@testable import Prime

final class SanitizedPhoneNumberTests: XCTestCase {

    func testNumberForNumbersReturnsSameInput() {
        let input = "79001234567"
        let result = SanitizedPhoneNumber(from: input)?.number
        XCTAssertEqual(input, result)
    }

    func testNumberForSigns() {
        let input = "+7-9,0;0#1%2^3&4*5)6(7_=-"
        let result = SanitizedPhoneNumber(from: input)?.number
        XCTAssertEqual(result, "79001234567")
    }

    func testNumberForSpaces() {
        let input = "7 900 123 45 67"
        let result = SanitizedPhoneNumber(from: input)?.number
        XCTAssertEqual(result, "79001234567")
    }

    func testNumberForLetters() {
        let input = "7a900b123c45d67"
        let result = SanitizedPhoneNumber(from: input)?.number
        XCTAssertEqual(result, "79001234567")
    }

    func testNumberForAnyCombination() {
        let input = "+7 (900) 123-45-67 lol"
        let result = SanitizedPhoneNumber(from: input)?.number
        XCTAssertEqual(result, "79001234567")
    }

    func testNumberForInvalidNumberReturnsNil() {
        let input = "NOT A NUMBER GUYS SORRY"
        let result = SanitizedPhoneNumber(from: input)?.number
        XCTAssertNil(result)
    }
}
