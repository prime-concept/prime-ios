import UIKit

extension UIEdgeInsets {
    func negated() -> UIEdgeInsets {
        UIEdgeInsets(top: -self.top, left: -self.left, bottom: -self.bottom, right: -self.right)
    }

	static func tlbr(_ top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) -> Self {
		Self.init(top: top, left: left, bottom: bottom, right: right)
	}
}
