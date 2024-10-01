import Foundation

extension String {
    public func pluralized(_ count: Int, languageCode: String = Locale.primeLanguageCode) -> String {
		Pluralizer.pluralized(self, count, languageCode: languageCode)
    }
    
	public func pluralized(
		_ format: String,
		_ count: Int,
		_ countFormatter: NumberFormatter? = nil,
		languageCode: String = Locale.primeLanguageCode
	) -> String {
        let value = Pluralizer.pluralized(self, count, languageCode: languageCode)
        var countString = count.description
        
        var result = format
        
        if let formatter = countFormatter {
            countString = formatter.string(from: NSNumber(value: count)) ?? countString
        }
        
        result = result.replacingOccurrences(of: "%@", with: value)
        result = result.replacingOccurrences(of: "%d", with: countString)
        
        return result
    }
}

extension AppDelegate {
    func setupPluralization() {
		with("ru") { langCode in
			let pluralizer = Pluralizer.pluralizer(for: langCode)
			pluralizer.register(key: "avia.passenger",
								.init(none: "пассажиров",
									  one: "пассажир",
									  few: "пассажира",
									  many: "пассажиров",
									  other: "пассажира"))
		}

		with("en") { langCode in
			let pluralizer = Pluralizer.pluralizer(for: langCode)
			pluralizer.register(key: "avia.passenger", .init(one: "passenger", other: "passengers"))
		}
    }
}

extension String {
    var asIntOrZero: Int {
        let cleanValue = self.replacing(regex: "[^\\d]", with: "")
        let int = Int(cleanValue) ?? 0
        
        return int
    }
}

extension Optional where Wrapped == String {
    var asIntOrZero: Int {
        (self ?? "").asIntOrZero
    }
}

public final class Pluralizer {
	private let langCode: String

	init(langCode: String) {
		self.langCode = langCode
	}

    private static var pluralizers = [String: Pluralizer]()
    private var data = [String: Pluralization]()
    
    fileprivate static func pluralizer(for langCode: String) -> Pluralizer {
        let langCode = langCode.lowercased()
        
        if let pluralizer = Self.pluralizers[langCode] {
            return pluralizer
        }
        
        let pluralizer = Pluralizer(langCode: langCode)
        Self.pluralizers[langCode] = pluralizer
        
        return pluralizer
    }
    
    fileprivate static func pluralized(
		_ key: String,
		_ count: Int,
		languageCode: String = Locale.primeLanguageCode
	) -> String {
        guard let pluralization = Self.pluralizer(for: languageCode).data[key] else {
            return key
        }
        
        return pluralization.value(for: count, of: key)
    }
    
    fileprivate func register(key: String, _ pluralization: Pluralization) {
		var pluralization = pluralization
		pluralization.langCode = self.langCode
        self.data[key] = pluralization
    }
}

fileprivate struct Pluralization {
	init(none: String, one: String, few: String, many: String, other: String) {
		self.none = none
		self.one = one
		self.few = few
		self.many = many
		self.other = other
	}

	// English
	init(one: String, other: String) {
		self.none = other
		self.one = one
		self.few = other
		self.many = other
		self.other = other
	}

	var langCode: String?
	let none: String
	let one: String
	let few: String
	let many: String
	let other: String

	fileprivate func value(for count: Int, of key: String) -> String {
        // swiftlint:disable:next empty_count
		if count == 0 {
			return self.none
		}

		if self.langCode == "en" {
			if count == 1 { return self.one }
			return self.many
		}

		if count % 10 == 1 && count % 100 != 11 {
			return self.one
		}

		if (count % 10 >= 2 && count % 10 <= 4) && !(count % 100 >= 12 && count % 100 <= 14) {
			return self.few
		}

		if (count % 10 == 0)
			|| (count % 10 >= 5 && count % 10 <= 9)
			|| (count % 100 >= 11 && count % 100 <= 14) {

			return self.many
		}

		return self.other
	}
}
