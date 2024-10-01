import Foundation

enum ContactsListType: String, CaseIterable {
    case phone
    case email
    case address

    var firstKey: String {
        self.rawValue
    }

    var typeKey: String {
        switch self {
        case .email, .phone:
            return "\(self.rawValue)Type"
        case .address:
            return "type"
        }
    }

    var typeIndex: Int {
        switch self {
        case .phone:
            return 0
        case .email:
            return 1
        case .address:
            return 2
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .email:
            return Localization.localize("profile.email")
        case .phone:
            return Localization.localize("profile.phones")
        case .address:
            return Localization.localize("profile.address")
        }
    }
}

struct ContactsListViewModel {
    let addButtonTitle: String
    var cellViewModels: [ContactsListTableViewCellViewModel]
}

struct ContactsListTableViewCellViewModel {
    let id: Int
    let title: String
    let subTitle: String
	var badgeText: String? = nil
    var separatorIsHidden: Bool = false
}
