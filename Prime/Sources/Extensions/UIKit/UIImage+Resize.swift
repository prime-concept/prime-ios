import UIKit

extension UIImage {
	func resize(to size: CGSize) -> UIImage {
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image { _ in
			self.draw(in: CGRect(origin: .zero, size: size))
		}
	}

	func resize(smallestDimesion: CGFloat) -> UIImage {
		var size = CGSize(width: smallestDimesion, height: smallestDimesion)
		let width = self.size.width, height = self.size.height

		if self.size.width > self.size.height {
			let ratio = width / height
			size.width *= ratio
		} else {
			let ratio = height / width
			size.height *= ratio
		}

		return resize(to: size)
	}
}
