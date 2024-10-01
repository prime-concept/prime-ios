import UIKit

struct CompletedTasksListHeaderItemViewModel {
    let type: TaskTypeEnumeration
    let count: Int
	let alpha: CGFloat
    var isSelected: Bool
	let isEnabled: Bool

	init(type: TaskTypeEnumeration, count: Int, alpha: CGFloat = 1, isSelected: Bool = false, isEnabled: Bool = true) {
        self.type = type
        self.count = count
		self.alpha = alpha
        self.isSelected = isSelected
		self.isEnabled = isEnabled
    }
}
