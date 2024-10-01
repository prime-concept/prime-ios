import PhoneNumberKit

struct ContactAdditionViewModel {
    let type: ContactsListType
    let mode: ContactAdditionMode
    var phoneViewModel: ContactAdditionPhoneFieldViewModel?
    var addressViewModel: ContactAdditionAddressFieldViewModel?
    var contact: String?
    var contactType: ContactTypeViewModel?
    var comment: String?
	var isPrimary: Bool? = nil

    func additionFieldViewModel(for type: ContactAdditionFieldType) -> ContactAdditionFieldViewModel {
        var value = ""
        switch type {
        case .country:
            value = self.addressViewModel?.country ?? ""
        case .city:
            value = self.addressViewModel?.city ?? ""
        case .street:
            value = self.addressViewModel?.street ?? ""
        case .apartment:
            value = self.addressViewModel?.apartment ?? ""
        case .house:
            value = self.addressViewModel?.house ?? ""
        case .comment:
            value = self.comment ?? ""
        case .type:
            value = self.contactType?.name ?? ""
        case .email:
            value = self.contact ?? ""
        case .phone:
            value = self.phoneViewModel?.number ?? ""
		case .primarySwitch:
			value = (self.isPrimary ?? false) ? "true" : "false"
        }

        return ContactAdditionFieldViewModel(type: type, value: value)
    }
}

enum ContactAdditionFieldType: String {
    case phone
    case email
    case country
    case city
    case street
    case house
    case apartment
    case type
    case comment
	case primarySwitch

    var text: String {
        switch self {
        case .country, .city, .type:
            return Localization.localize("profile.\(self.rawValue)") + "*"
        default:
            return Localization.localize("profile.\(self.rawValue)")
        }
    }

    var validationText: String {
        switch self {
        case .phone:
            return "profile.phone.validation.alert.message".localized
        default:
            return "profile.validation.alert.message".localized
        }
    }
}

struct ContactAdditionPhoneFieldViewModel {
    let code: String
    let number: String

    init(phoneNumber: String) {
        let phoneNumberKit = PhoneNumberKit()
        guard let parsedNumber = try? phoneNumberKit.parse(phoneNumber, addPlusIfFails: true) else {
            self.code = "+7"
            self.number = ""
            return
        }
        self.code = "+" + String(parsedNumber.countryCode)
        self.number = phoneNumberKit.format(parsedNumber, toType: .international, withPrefix: false)
    }
}

struct ContactAdditionAddressFieldViewModel {
    let country: String
    let city: String
    let street: String
    let house: String
    let apartment: String

    init(from address: Address) {
        self.country = address.country?.name ?? ""
        self.city = address.city?.name ?? ""
        self.street = address.street ?? ""
        self.house = address.house ?? ""
        self.apartment = address.flat ?? ""
    }

    var fullAddress: String {
        "\(self.country), \(self.city), \(self.street), \(self.house), \(self.apartment)"
    }
}

struct ContactAdditionFieldViewModel {
    let type: ContactAdditionFieldType
    let value: String
}
