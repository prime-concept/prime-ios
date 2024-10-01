import Foundation

public extension Locale {
	public static var primeLanguageCode: String {
		var language: String! = Locale.current.languageCode
		if language != "ru" { language = "en" }

		return language
	}
}
