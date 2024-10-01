import XCTest
@testable import Prime
@testable import PhoneNumberKit

final class PhoneNumberKitTests: XCTestCase {
    private var phoneNumberKit: PhoneNumberKit!

    override func setUpWithError() throws {
        phoneNumberKit = PhoneNumberKit()
    }

    func testValidNumberAddPlusTrueParsesOK() {
        let number = "+79051234567"
        XCTAssertNoThrow(try phoneNumberKit.parse(number, addPlusIfFails: true))
    }

    func testValidNumberAddPlusFalseParsesOK() {
        let number = "+79051234567"
        XCTAssertNoThrow(try phoneNumberKit.parse(number, addPlusIfFails: false))
    }

    func testInvalidNumberAddPlusTrueParsesOK() {
        let number = "79051234567"
        XCTAssertNoThrow(try phoneNumberKit.parse(number, addPlusIfFails: true))
    }

    func testInvalidNumberAddPlusTrueParsingFails() {
        let number = "not a number"
        XCTAssertThrowsError(try phoneNumberKit.parse(number, addPlusIfFails: true))
    }
}
