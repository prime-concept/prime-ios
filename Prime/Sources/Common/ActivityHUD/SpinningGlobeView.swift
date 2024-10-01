import UIKit

class SpinningGlobeView: UIView {
	private let globeImage = UIImage(named: "loader_globe")!
	private lazy var widthRatio = self.globeImage.size.width / self.globeImage.size.height

	private lazy var firstImageView = UIImageView(image: self.globeImage)
	private lazy var secondImageView = UIImageView(image: self.globeImage)

	private(set) var isAnimating = false

	private var pendingAnimationCancelBlock: (() -> Void)?

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.clipsToBounds = true

		self.layer.borderColorThemed = Palette.shared.accentLoader
		self.firstImageView.tintColorThemed = Palette.shared.accentLoader
		self.secondImageView.tintColorThemed = Palette.shared.accentLoader

		self.addSubview(self.firstImageView)
		self.addSubview(self.secondImageView)
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		self.layer.cornerRadius = self.bounds.height / 2
		self.layer.borderWidth = self.bounds.height / 16

		if !self.isAnimating {
			self.positionImageViews()
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func startAnimating(force: Bool = false) {
		if self.window == nil {
			self.isAnimating = true
			return
		}

		if !force {
			if self.isAnimating { return }
		}

		onMain {
			self.isAnimating = true
			self.animate()
		}
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()

		if self.window == nil {
			return
		}

		onMain {
			if self.isAnimating {
				self.startAnimating(force: true)
			}
		}
	}

	private func animate() {
		self.positionImageViews()
		self.bounds.origin.x = 0

		UIView.animate(
			withDuration: 2,
			delay: 0,
			options: [.curveEaseInOut],
			animations: {
				self.bounds.origin.x = self.firstImageView.bounds.width
			},
			completion: { _ in
				self.pendingAnimationCancelBlock?()
				self.pendingAnimationCancelBlock = nil

				if self.isAnimating, self.window != nil {
					self.animate()
				} else {
					self.bounds.origin.x = 0
					self.positionImageViews()
				}
			}
		)
	}

	func stopAnimating() {
		guard self.isAnimating else {
			return
		}

		self.pendingAnimationCancelBlock = { [weak self] in
			self?.isAnimating = false
		}
	}

	private func positionImageViews() {
		[self.firstImageView, self.secondImageView].forEach { imageView in
			imageView.bounds.size.height = self.bounds.height
			imageView.bounds.size.width = self.bounds.height * self.widthRatio
		}

		self.firstImageView.frame.origin = .zero
		self.secondImageView.frame.origin = CGPoint(x: self.firstImageView.bounds.width, y: 0)
	}
}
