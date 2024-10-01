import UIKit

extension UIButton {
	func setBackgroundColor(
		_ backgroundColor: UIColor?,
		for state: UIButton.State,
		bounds: CGRect? = nil,
		cornerRaduis: CGFloat? = nil
	) {
		attempt(every: 0.1, maxCount: 100) { [weak self] retry in
			let bounds = bounds ?? self?.bounds ?? .zero

			guard let self = self, bounds != .zero else {
				return
			}

			let cornerRaduis = cornerRaduis ?? self.layer.cornerRadius

			if bounds == .zero {
				retry()
				return
			}

			UIGraphicsBeginImageContext(bounds.size)

			guard let context = UIGraphicsGetCurrentContext() else {
				retry()
				return
			}

			UIBezierPath(
				roundedRect: bounds,
				cornerRadius: cornerRaduis
			).addClip()

			context.setFillColor((backgroundColor ?? .clear).cgColor)
			context.fill(bounds)

			let image = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()

			self.setBackgroundImage(image, for: state)
		}
	}
}
