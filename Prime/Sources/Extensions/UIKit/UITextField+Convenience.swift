import UIKit

extension UITextField {
	func updateKeepingCursor(updateBlock: () -> Void) {
		guard let selectedRange = self.selectedTextRange else {
			updateBlock()
			return
		}

		let cursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.start)

		updateBlock()

		onMain {
			if let newPosition = self.position(from: self.beginningOfDocument, offset: cursorPosition) {
				self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
			}
		}
	}
}
