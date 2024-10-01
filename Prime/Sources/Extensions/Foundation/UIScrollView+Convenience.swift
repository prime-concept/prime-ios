import UIKit

enum PrimeScrollViewDirection {
	case top
	case bottom
	case leading
	case trailing
}

extension UIScrollView {
	func scroll(to direction: PrimeScrollViewDirection, animated: Bool = true) {
		let offset: CGPoint

		switch direction {
			case .top:
				offset = .init(x: 0, y: self.contentInset.top)
			case .bottom:
				offset = .init(x: 0, y: self.contentSize.height - self.bounds.height + self.contentInset.bottom)
			case .leading:
				offset = .init(x: self.contentInset.left, y: 0)
			case .trailing:
				offset = .init(x: self.contentSize.width - self.bounds.width + self.contentInset.top, y: 0)
		}

		self.setContentOffset(offset, animated: animated)
	}
}
