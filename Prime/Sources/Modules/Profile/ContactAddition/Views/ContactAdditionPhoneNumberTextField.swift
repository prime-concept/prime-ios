import PhoneNumberKit

final class ContactAdditionPhoneNumberTextField: PhoneNumberTextField {
    func set(with code: String) {
        self.partialFormatter.defaultRegion = code
    }
}
