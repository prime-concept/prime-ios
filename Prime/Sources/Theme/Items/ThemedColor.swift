import UIKit

typealias ThemedColor = ThemedItem<UIColor>

extension ThemedItem where ElementType == UIColor {
	func withAlphaComponent(_ alpha: CGFloat) -> ThemedColor {
		self.addDecorator { color in
			color.withAlphaComponent(alpha)
		}
	}
}

extension Int {
	var asUIColor: UIColor {
		UIColor(hex: self)
	}

	var themedColor: ThemedColor {
		ThemedColor(self.asUIColor)
	}

	func themedColor(_ id: String) -> ThemedColor {
		ThemedColor(self.asUIColor, id: id)
	}
}
