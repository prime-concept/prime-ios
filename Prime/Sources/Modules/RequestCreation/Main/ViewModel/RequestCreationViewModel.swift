import UIKit

struct RequestCreationCategoriesViewModel {
    struct Button {
        let id: Int
        let image: UIImage?
        let title: String
    }
    let topRow: [Button]
    let bottomRow: [Button]
    let selectedId: Int?
    let onCategorySelected: ((Int) -> Void)
}

struct TaskAccessoryHeaderViewModel {
    struct Button {
        let title: String
        let imageName: String?
        let onTap: (() -> Void)
    }
	enum Selected {
		case existing
		case new
	}
    let title: String
	let existingButton: Button
	let newButton: Button
	let selected: Selected
}
