import UIKit
import  PhoneNumberKit

struct CountryCode {
    let code: String
    let country: String
    var isSelected: Bool = false

    static var defaultCountryCode: CountryCode {
        let regionCode = PhoneNumberKit.defaultRegionCode()
        let kit = PhoneNumberKit()
        guard let countryCode = kit.countryCode(for: regionCode),
              let country = kit.mainCountry(forCode: countryCode) else {
            fatalError("NO COUNTRY CODE & COUNTRY IN PHONENUMBERKIT FOR CODE: \(regionCode)")
        }
        let stringCountryCode = String(countryCode)
        let defaultCountryCode = CountryCode(code: stringCountryCode, country: country, isSelected: true)
        return defaultCountryCode
    }
}


