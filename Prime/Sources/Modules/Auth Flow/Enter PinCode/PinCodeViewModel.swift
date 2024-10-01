import Foundation

enum Biometry: String {
    case faceID = "Face ID"
    case touchID = "Touch ID"

    var buttonTitle: String {
        switch self {
        case .faceID:
            return Localization.localize("auth.loginWithFaceID")
        case .touchID:
            return Localization.localize("auth.loginWithTouchID")
        }
    }
}

enum PinCodeShowAction {
	case inputPin
	case confirmPin
    case notifyError
}

enum PinCodeMode: Equatable {
    case createPin
	case confirmPin
    case login(username: String)
}

struct PinCodeViewModel {
    let title: String

    let mode: PinCodeMode
    let action: PinCodeShowAction
    let biometry: Biometry?
}
