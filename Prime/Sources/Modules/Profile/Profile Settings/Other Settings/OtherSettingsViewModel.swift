import Foundation

struct OtherSettingViewModel {
	internal init(
		title: String,
		value: String,
		kind: OtherSettingViewModel.Kind,
		action: (() -> Void)? = nil,
		isLast: Bool
	) {
		self.title = title
		self.value = value
		self.kind = kind
		self.action = action
		self.isLast = isLast
	}

	enum Kind {
		case text
		case toggle
		case button
	}

    let title: String
    let value: String
	let kind: Kind

	var action: (() -> Void)?
	
    let isLast: Bool
}

enum OtherSettings: CaseIterable {
	case passwordToggle
	case deleteCachedDocuments
    case releaseVersion
    case buildVersion

	var title: String {
		switch self {
			case .passwordToggle:
				return "profile.settings.toggle.password".localized
			case .deleteCachedDocuments:
				return "profile.settings.delete.cached.documents".localized
			case .releaseVersion:
				return "profile.settings.release.version".localized
			case .buildVersion:
				return "profile.settings.build.version".localized
		}
	}

	var value: String {
		switch self {
			case .passwordToggle:
				return "profile.settings.toggle.password"
			case .deleteCachedDocuments:
				return ""
			case .releaseVersion:
				return Bundle.main.releaseVersionNumberPretty
			case .buildVersion:
				return Bundle.main.buildVersionNumber
		}
	}

	var kind: OtherSettingViewModel.Kind {
		switch self {
			case .releaseVersion:
				return .text
			case .buildVersion:
				return .text
			case .passwordToggle:
				return .toggle
			case .deleteCachedDocuments:
				return .button
		}
	}
}
