import Nuke
import UIKit

extension UIImage {
	@ThreadSafe
	private static var imageViewsCache = [UIImageView]()

	static func load(from url: URL, completion: ((UIImage?) -> Void)? = nil) {
		let imageView = UIImageView()
		self.imageViewsCache.append(imageView)

		imageView.loadImage(from: url) { image in
			completion?(image)
			self.imageViewsCache.removeAll { $0 === imageView }
		}
	}
}

extension UIImageView {
	func loadImage(from url: URL, completion: ((UIImage?) -> Void)? = nil) {
		Nuke.loadImage(with: ImageRequest(url: url), into: self, completion: { result in
			switch result {
				case .success(let response):
					completion?(response.image)
				case .failure(_):
					completion?(nil)
			}
		})
    }
}
