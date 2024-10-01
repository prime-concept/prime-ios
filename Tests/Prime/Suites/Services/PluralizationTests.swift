import XCTest

class PluralizationTests: XCTestCase {
    func testEnglishPluralization() {
        let key = "avia.passenger"
        let langCode = "en"

        XCTAssertEqual(key.pluralized(0, languageCode: langCode), "passengers")
        XCTAssertEqual(key.pluralized(1, languageCode: langCode), "passenger")
        XCTAssertEqual(key.pluralized(2, languageCode: langCode), "passengers")
        XCTAssertEqual(key.pluralized(5, languageCode: langCode), "passengers")
		XCTAssertEqual(key.pluralized(11, languageCode: langCode), "passengers")
		XCTAssertEqual(key.pluralized(21, languageCode: langCode), "passengers")
    }

    func testRussianPluralization() {
        let key = "avia.passenger"
        let langCode = "ru"

        XCTAssertEqual(key.pluralized(0, languageCode: langCode), "пассажиров")
        XCTAssertEqual(key.pluralized(1, languageCode: langCode), "пассажир")
        XCTAssertEqual(key.pluralized(2, languageCode: langCode), "пассажира")
        XCTAssertEqual(key.pluralized(5, languageCode: langCode), "пассажиров")
		XCTAssertEqual(key.pluralized(11, languageCode: langCode), "пассажиров")
		XCTAssertEqual(key.pluralized(21, languageCode: langCode), "пассажир")
    }
}
