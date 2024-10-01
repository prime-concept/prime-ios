import UIKit

enum ProfileEditFormField {
    case textField(ProfileEditTextFieldModel)
    case datePicker(ProfileEditDatePickerModel)
    case emptySpace(CGFloat)
}

struct ProfileEditTextFieldModel {
    let title: String
    let placeholder: String
    let value: String
    let fieldType: FieldType
    let onUpdate: (String) -> Void

    enum FieldType {
        case givenName
        case familyName
        case middleName

        var keyboardType: UIKeyboardType {
            .namePhonePad
        }

        var contentType: UITextContentType? {
            switch self {
            case .familyName:
                return .familyName
            case .givenName:
                return .givenName
            case .middleName:
                return .middleName
            }
        }
    }
}

struct ProfileEditDatePickerModel {
    let title: String
    let placeholder: String
    let value: String
    let onSelect: (Date) -> Void
}
