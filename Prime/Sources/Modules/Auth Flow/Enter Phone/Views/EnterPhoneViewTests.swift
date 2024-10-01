import XCTest
@testable import Prime

final class EnterPhoneViewTests: XCTestCase {

    private var enterPhoneViewPresenter: EnterPhoneViewPresenterProtocol!

    override func setUpWithError() throws {
        let enterPhoneView = EnterPhoneView()
        enterPhoneViewPresenter = EnterPhoneViewDefaultPresenter(phoneNumberKit: enterPhoneView.phoneTextField.phoneNumberKit)
    }

    func testNoPlusLeadingSevenNoSpacesProcessesOk() {
        let input = "79039469210"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testNoPlusLeadingSevenSpacesProcessesOk() {
        let input = "7 903 946 92 10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testNoPlusLeadingSevenSpacesAndHyphensProcessesOk() {
        let input = "7 903 946-92-10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testPlusLeadingSevenNoSpacesProcessesOk() {
        let input = "+79039469210"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testPlusLeadingSevenSpacesProcessesOk() {
        let input = "+7 903 946 92 10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testPlusLeadingSevenSpacesAndHyphensProcessesOk() {
        let input = "+7 903 946-92-10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }


    func testNoPlusLeadingEightNoSpacesProcessesOk() {
        let input = "89039469210"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testNoPlusLeadingEightSpacesProcessesOk() {
        let input = "8 903 946 92 10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testNoPlusLeadingEightSpacesAndHyphensProcessesOk() {
        let input = "8 903 946-92-10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testPlusLeadingEightNoSpacesProcessesOk() {
        let input = "+89039469210"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testPlusLeadingEightSpacesProcessesOk() {
        let input = "+8 903 946 92 10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    func testPlusLeadingEightSpacesAndHyphensProcessesOk() {
        let input = "+8 903 946-92-10"
        let reference = "+79039469210"

        let result = enterPhoneViewPresenter.phoneNumber(from: input)

        let unformattedResult = unformat(result)

        XCTAssertEqual(reference, unformattedResult, "EnterPhoneView must produce \(reference) for \(input). Actual result: \(unformattedResult)")
    }

    private func unformat(_ phoneNumber: String) -> String {
        phoneNumber.replacingOccurrences(of: "[^0-9\\+]", with: "", options: .regularExpression)
    }
}
