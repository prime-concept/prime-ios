import XCTest
@testable import Prime

final class DeeplinkServiceTests: XCTestCase {
	private let deeplinkService = DeeplinkService()
	
	func testCorrectYandexLinkWithCorrectDeeplinkProcessedOK() {
		let link = "https://4393888.redirect.appmetrica.yandex.com/profile?appmetrica_tracking_id=1"
		let url = URL(string: link)!

		let success = self.deeplinkService.process(url: url)
		XCTAssertTrue(success, "Correct Yandex Appmetrica redirect URL must be processed!")
	}

	func testCorrectYandexLinkWithIncorrectDeeplinkFailed() {
		let link = "https://4393888.redirect.appmetrica.yandex.com/FAKE_DEEPLINK_PATH?appmetrica_tracking_id=1"
		let url = URL(string: link)!

		let success = self.deeplinkService.process(url: url)
		XCTAssertFalse(success, "Correct Yandex Appmetrica redirect URL with fake deeplink path must be ignored!")
	}

	func testIncorrectYandexLinkWithCorrectDeeplinkFailed() {
		let link = "https://4393888.home.appmetrica.yandex.com/profile?appmetrica_tracking_id=1"
		let url = URL(string: link)!

		let success = self.deeplinkService.process(url: url)
		XCTAssertFalse(success, "Incorrect Yandex Appmetrica redirect URL with correct deeplink path must be ignored!")
	}

	func testIncorrectYandexLinkWithIncorrectDeeplinkFailed() {
		let link = "https://4393888.home.appmetrica.yandex.com/FAKE_DEEPLINK_PATH?appmetrica_tracking_id=1"
		let url = URL(string: link)!

		let success = self.deeplinkService.process(url: url)
		XCTAssertFalse(success, "Incorrect Yandex Appmetrica redirect URL with fake deeplink path must be ignored!")
	}

	func testSubsequentProcessingOfSameURLIsIgnored() {
		let link = "https://4393888.redirect.appmetrica.yandex.com/profile?appmetrica_tracking_id=1"
		let url = URL(string: link)!

		let firstProcess = self.deeplinkService.process(url: url)
		XCTAssertTrue(firstProcess, "Correct Yandex Appmetrica redirect URL must be processed!")

		let secondProcess = self.deeplinkService.process(url: url)
		XCTAssertFalse(secondProcess, "Subsequent same correct Yandex Appmetrica redirect URL must be ignored!")
	}
}
