import UIKit

class GlobeRefreshControl: UIRefreshControl {
	private let globeView: SpinningGlobeView!
	private let diameter: CGFloat

	init(diameter: CGFloat = 44) {
		self.diameter = diameter
		self.globeView = SpinningGlobeView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))

		super.init(frame: .zero)
		self.placeGlobeView()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func placeGlobeView() {
		globeView.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(globeView)
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		self.layoutGlobe()

		for subview in self.subviews where !(subview is SpinningGlobeView) {
			subview.alpha = 0
		}
	}

	private func layoutGlobe() {
		let scale = min(1, (abs(self.frame.origin.y) / self.diameter))
		self.globeView.alpha = scale

		self.globeView.center = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
		self.globeView.bounds.size = CGSize(width: self.diameter * scale, height: self.diameter * scale)

		if !self.globeView.isAnimating, scale >= 1 {
			self.globeView.startAnimating()
		}

		if self.globeView.isAnimating, scale < 0.5 {
			self.globeView.stopAnimating()
		}
	}
}
