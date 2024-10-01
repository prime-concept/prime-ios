import UIKit

struct ProfileViewModel {
    let cardViewModel: ProfileCardViewModel
    let personalInfoViewModel: ProfilePersonalInfoViewModel
	let loadingSucceeded: Bool
}

struct ProfileCardViewModel {
    let name: String
    let userName: String
    let expiryDate: Date?
    let clubCard: String?
    let isAddedToWallet: Bool
    let addCardTap: () -> Void
}

struct ProfilePersonalInfoViewModel {
    let cellViewModels: [ProfilePersonalInfoCellViewModel]
}

struct ProfilePersonalInfoCellViewModel {
    internal init(
        title: String,
        count: String = "",
        items: [ProfilePersonalInfoCellViewModel.Item],
        supportedItemNames: [String],
        onCountTap: (() -> Void)? = nil,
        openDetailsOnTabWithIndex: @escaping (Int, Bool) -> Void
    ) {
        self.title = title
        self.count = count
        self.items = items
        self.supportedItemNames = supportedItemNames
        self.onCountTap = onCountTap
        self.openDetailsOnTabWithIndex = openDetailsOnTabWithIndex
    }
    
    struct Item {
        internal init(title: String, count: String = "", content: ProfilePersonalInfoCellViewModel.Item.Content) {
            self.title = title
            self.count = count
            self.content = content
        }
        
		enum Content {
			case plain(UIImage?)
			case cards([String], [UIColor])
			case empty(String, String)
            case family(UIImage?)
		}

		let title: String
		let count: String
		let content: Content
	}

	let title: String
	let count: String
	let items: [Item]
	let supportedItemNames: [String]

	let onCountTap: (() -> Void)?
	let openDetailsOnTabWithIndex: (Int, Bool) -> Void
}
