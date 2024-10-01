import Foundation

enum Localization {
    static func localize(_ key: String) -> String {
        // swiftlint:disable nslocalizedstring_key
        NSLocalizedString(key, comment: "")
    }
}

extension String {
    var localized: String {
        Localization.localize(self)
    }

	var brandLocalized: String {
		self.localized(from: "Branding")
	}

	func localized(from table: String) -> String {
		NSLocalizedString(
			self,
			tableName: table,
			bundle: Bundle.main,
			comment: ""
		)
	}

	func localized(_ lanCode: String) -> String {
		guard let bundlePath = Bundle.main.path(forResource: lanCode, ofType: "lproj"),
			  let bundle = Bundle(path: bundlePath) else {
			return ""
		}

		return NSLocalizedString(
			self,
			bundle: bundle,
			value: " ",
			comment: ""
		)
	}
}
