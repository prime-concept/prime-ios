import UIKit

extension UINavigationController {
	convenience init(
		rootViewController: UIViewController,
		navigationBarClass: AnyClass? = CrutchyNavigationBar.self,
		toolbarClass: AnyClass? = nil
	) {
		self.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
		self.viewControllers = [rootViewController]
	}
}

class CrutchyNavigationBar: UINavigationBar {
	private lazy var imageView = UIImageView()

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.addSubview(self.imageView)
		self.imageView.contentMode = .scaleToFill
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func setBackgroundImage(
		_ backgroundImage: UIImage?,
		for barMetrics: UIBarMetrics
	) {
		self.imageView.image = backgroundImage
	}

	override func setBackgroundImage(
		_ backgroundImage: UIImage?,
		for barPosition: UIBarPosition,
		barMetrics: UIBarMetrics
	) {
		self.imageView.image = backgroundImage
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.enforceBackgroundImage()
	}

	private func enforceBackgroundImage() {
		let backgroundView = self.subviews.first {
			NSStringFromClass(type(of: $0)) == "_UIBarBackground"
		}

		self.sendSubviewToBack(self.imageView)

		if let view = backgroundView {
			view.alpha = 0.01
			self.imageView.frame = view.frame
		} else {
			self.imageView.frame = self.frame
		}
	}
}
