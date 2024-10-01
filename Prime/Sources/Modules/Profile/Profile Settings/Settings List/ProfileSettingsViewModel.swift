import UIKit

struct ProfileSettingViewModel {
    let icon: String?
    let title: String
	let titleColor: ThemedColor
	var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 44)
}

enum ProfileSettings: CaseIterable {
	case personalData
	case expenses
	case other
	case personalDataPolicy
	case offer
	case deleteAccount
	case exit

	var title: String {
		switch self {
		case .personalData:
			return Localization.localize("profile.settings.personalData")
		case .expenses:
			return Localization.localize("profile.settings.expenses")
		case .personalDataPolicy:
			return Localization.localize("profile.settings.personal.info.policy")
		case .offer:
			return Localization.localize("profile.settings.personal.offer")
		case .other:
			return Localization.localize("profile.settings.other")
		case .deleteAccount:
			return Localization.localize("profile.settings.delete.account")
		case .exit:
			return Localization.localize("profile.settings.exit")
		}
	}

	var icon: String? {
		switch self {
		case .personalData:
			return "personal_data_icon"
		case .expenses:
			return "expenses_icon"
		case .other:
			return "settings_icon"
		case .personalDataPolicy:
			return "profile_info_icon"
		case .offer:
			return "profile_info_icon"
		default:
			return nil
		}
	}
}
