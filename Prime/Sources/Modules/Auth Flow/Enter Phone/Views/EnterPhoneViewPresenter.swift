import Foundation
import PhoneNumberKit

protocol EnterPhoneViewPresenterProtocol {
    func phoneNumber(from string: String) -> String
}

class EnterPhoneViewDefaultPresenter: EnterPhoneViewPresenterProtocol {
    init(phoneNumberKit: PhoneNumberKit? = nil) {
        self.phoneNumberKit = phoneNumberKit
    }

    var phoneNumberKit: PhoneNumberKit?

    func phoneNumber(from string: String) -> String {
        var number = string

        if !number.hasPrefix("+") {
            number = "+" + number
        }

        if let fixedRussianNumber = fixedRussianNumber(in: number) {
            return fixedRussianNumber
        }

        return number
    }

    private func fixedRussianNumber(in string: String) -> String? {
        let russianPrefix = "^\\+?\\s*(7|8)"

        guard string.contains(regex: russianPrefix) else {
            return nil
        }

        let fixedRussianNumber = string.replacing(regex: russianPrefix, with: "+7")

        let russianNumberParsed = try? phoneNumberKit?.parse(fixedRussianNumber)
        if russianNumberParsed?.numberString != nil {
            return fixedRussianNumber
        }

        return nil
    }
}
