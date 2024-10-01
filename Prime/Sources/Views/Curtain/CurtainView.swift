import UIKit

private class CurtainContentView: UIView {
	var onLayoutSubviews: (() -> Void)?

	private var latestBounds: CGRect?

	override func layoutSubviews() {
		super.layoutSubviews()

		if self.latestBounds != self.bounds {
			self.latestBounds = self.bounds
			self.onLayoutSubviews?()
		}

		self.latestBounds = self.bounds
	}
}

class CurtainView: UIView {
	struct Appearance: Codable {
		var curtainColor = Palette.shared.gray5
		var grabberColor = Palette.shared.gray3
		var shadowColor = Palette.shared.black.withAlphaComponent(0.1)

		var curtainCornerRadius: CGFloat = 20
		var grabberSize: CGSize = CGSize(width: 40, height: 4)
	}

	var animationDuration = 0.3
	var animatedMoveToWindow = true

	var magneticRatios: [CGFloat] = [0.5]
	var toggleRatio: CGFloat = 0.3

	var mimicksFullscreenWhenExpanded: Bool = false
	var hidesOnPanToBottom: Bool = true

	var willAnimateMagneticScroll: ((CGFloat, CGFloat, CGFloat) -> Void)? = nil
	var animateAlongsideMagneticScroll: ((CGFloat, CGFloat, CGFloat) -> Void)? = nil
	var didAnimateMagneticScroll: ((CGFloat, CGFloat) -> Void)? = nil
	var didPan: ((CGFloat) -> Void)? = nil

	var currentRatio: CGFloat = 0

	private let appearance: Appearance
	private(set) var content: UIView
	private var isAnimating: Bool = false

	private var contentInset: UIEdgeInsets
	private var contentTopConstraint: NSLayoutConstraint!
	private var curtainTopConstraint: NSLayoutConstraint!

	private var latestTranslationY: CGFloat? = nil {
		willSet {
			self.previousTranslationY = self.latestTranslationY
		}
	}

	private var previousTranslationY: CGFloat? = nil

	private var isGoingUp: Bool {
		guard let previous = self.previousTranslationY, let current = self.latestTranslationY else {
			return false
		}

		return previous > current
	}

	private(set) lazy var curtain: UIView = CurtainContentView { (curtain: CurtainContentView) in
		let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
		curtain.addGestureRecognizer(panRecognizer)
		curtain.isUserInteractionEnabled = true
		curtain.layer.masksToBounds = true
	}

	private lazy var grabber = UIView()
    
    var setCurtainBackgroundThemedColor: ThemedColor? {
        didSet {
            if let colorThemed = setCurtainBackgroundThemedColor {
                self.curtain.backgroundColorThemed = colorThemed
            }
        }
    }

	private var initialRatio: CGFloat

	init(
		appearance: Appearance = Appearance(),
		content: UIView,
		contentInset: UIEdgeInsets = .init(top: 30, left: 0, bottom: 0, right: 0),
		initialRatio: CGFloat = 1.0
	) {
		self.appearance = appearance

		self.content = content
		self.contentInset = contentInset

		self.initialRatio = initialRatio

		super.init(frame: .zero)

		self.content.setContentHuggingPriority(.required, for: .vertical)
		self.content.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

		self.addSubview(self.curtain)
		self.curtain.addSubview(content)

		self.setupGrabber()
		self.setupCurtain()
		self.setupContent()

		self.scrollTo(ratio: initialRatio, animated: false)
	}

	private func setupContent() {
		self.content.layer.masksToBounds = true
		self.content.layer.cornerRadius = self.appearance.curtainCornerRadius
		self.content.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

		self.contentTopConstraint = self.content.make(.edges(except: .bottom), .equalToSuperview, [
			self.contentInset.top,
			self.contentInset.left,
			self.contentInset.right
		])[0]

		self.content.make(.bottom, .equalToSuperview, priority: .defaultLow)
	}

	private func setupGrabber() {
		self.curtain.addSubview(self.grabber)

		self.grabber.backgroundColorThemed = self.appearance.grabberColor
		self.grabber.layer.cornerRadius = self.appearance.grabberSize.height / 2

		self.grabber.make(.top, .equalToSuperview, 10)
		self.grabber.make(.centerX, .equalToSuperview)
		self.grabber.make(.size, .equal, [self.appearance.grabberSize.width, self.appearance.grabberSize.height])
	}

	private func setupCurtain() {
		self.curtainTopConstraint = self.curtain.make(.edges(except: .bottom), .equalToSuperview)[0]

		self.curtain.backgroundColorThemed = self.appearance.curtainColor
		self.curtain.layer.cornerRadius = self.appearance.curtainCornerRadius
		self.curtain.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

		self.curtain.dropShadow(
			offset: CGSize(width: 0, height: -2),
			radius: 5,
			color: self.appearance.shadowColor
		)

		let tail = UIView()
		self.insertSubview(tail, belowSubview: self.curtain)
		tail.make(.width, .equal, to: self.curtain)
		tail.make(.height, .equal, UIScreen.main.bounds.height)
		tail.place(under: self.curtain, -1)

		tail.backgroundColor = self.curtain.backgroundColor
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		self.curtain.frame.contains(point)
	}

	private func constrainCurtain(top: CGFloat) {
		var top = top - self.safeAreaInsets.bottom
		top = max(self.safeAreaInsets.top, top)

		self.curtainTopConstraint.constant = top
	}

	func scrollTo(ratio: CGFloat, animated: Bool = true) {
		let duration = animated ? self.animationDuration : 0

		let selfHeight = self.bounds.height
		let curtainHeight = self.curtain.sizeFor(width: self.curtain.bounds.width).height

		let curtainVisibleHeight = ratio * curtainHeight

		let top = selfHeight - curtainVisibleHeight
		if top != top {
			return
		}

		self.setNeedsLayout()

		self.constrainCurtain(top: top)

		self.currentRatio = ratio

		let oldRatio = self.currentRatio
		self.willAnimateMagneticScroll?(oldRatio, ratio, duration)

		UIView.animate(withDuration: duration, animations: {
			self.layoutIfNeeded()
			self.animateAlongsideMagneticScroll?(oldRatio, ratio, duration)
			self.toggleFullscreenStateIfNeeded()
		}) { _ in
			self.didAnimateMagneticScroll?(oldRatio, ratio)
			self.didPan?(ratio)
		}
	}

	@objc
	private func onPan(_ recognizer: UIPanGestureRecognizer) {
		let view = recognizer.view

		let velocityY = recognizer.velocity(in: self).y
		let locationY = recognizer.location(in: self).y

		if locationY < 0 || locationY >= self.bounds.height - self.contentInset.top {
			self.scrollToNearestMagneticPoint()
			self.latestTranslationY = nil
			return
		}

		switch recognizer.state {
			case .ended, .failed, .cancelled:
				self.scrollToNearestMagneticPoint(velocity: velocityY)
				self.latestTranslationY = nil
				return
			default:
				break
		}

		let translationY = recognizer.translation(in: view).y

		defer {
			self.latestTranslationY = translationY
			self.didPan?(self.currentRatio)
			self.toggleFullscreenStateIfNeeded()
		}

		guard let latestTranslationY = self.latestTranslationY else {
			return
		}

		let delta = latestTranslationY - translationY
		let newTop = self.curtainTopConstraint.constant - delta

		self.constrainCurtain(top: newTop + self.safeAreaInsets.bottom)

		let fullHeight = self.curtain.bounds.height + self.safeAreaInsets.bottom
		let visibleHeight = self.bounds.height - newTop
		self.currentRatio = visibleHeight / fullHeight
	}

	private func toggleFullscreenStateIfNeeded() {
		guard self.mimicksFullscreenWhenExpanded else {
			return
		}

		let currentRatio = self.currentRatio

		var shouldMimickFullscreen = currentRatio > 0.95
									 && self.curtain.layer.cornerRadius != 0
									 &&	self.curtain.bounds.height >= self.bounds.height

		shouldMimickFullscreen = shouldMimickFullscreen || (currentRatio != currentRatio)

		let shouldResignFullscreen = currentRatio <= 0.95 && self.curtain.layer.cornerRadius == 0

		guard shouldResignFullscreen || shouldMimickFullscreen else {
			return
		}
		
		UIView.animate(withDuration: 0.25) {
			self.curtain.layer.cornerRadius = shouldMimickFullscreen ? 0 : self.appearance.curtainCornerRadius
			self.grabber.alpha = shouldMimickFullscreen ? 0 : 1
		}
	}

	private func scrollToNearestMagneticPoint(
		duration: TimeInterval = 0.3,
		velocity: CGFloat = 0
	) {
		if self.isAnimating {
			return
		}

		var nearestY: CGFloat? = nil
		let currentY = self.curtainTopConstraint.constant

		let magneticYs = Set(self.magneticRatios)
			.union(hidesOnPanToBottom ? [0, 1] : [1])
			.sorted(by: <)
			.map { (1 - $0, self.bounds.height - ((1 - $0) * self.curtain.bounds.height)) }

		if currentY < magneticYs.first!.1 {
			nearestY = magneticYs.first!.1
		} else if currentY > magneticYs.last!.1 {
			nearestY = magneticYs.last!.1
		} else {
			for i in 0..<magneticYs.count - 1 {
				let firstY = magneticYs[i].1
				let secondY = magneticYs[i + 1].1
				guard currentY > firstY, currentY < secondY else {
					continue
				}

				if velocity > 1000 {
					nearestY = secondY
					break
				}

				if velocity < -1000 {
					nearestY = firstY
					break
				}

				let interval = secondY - firstY
				let translation1 = abs(firstY - currentY)

				nearestY = firstY

				if self.isGoingUp {
					if translation1 > (1 - self.toggleRatio) * interval {
						nearestY = secondY
					}
				} else {
					if translation1 > self.toggleRatio * interval {
						nearestY = secondY
					}
				}

				break
			}
		}

		guard let nearestY else {
			return
		}

		let oldRatio = self.currentRatio
		let magenticRatio = magneticYs.first{ $0.1 == nearestY }!.0

		var duration = duration
		let travelDistance = abs(self.curtainTopConstraint.constant - nearestY)

		if travelDistance != 0 {
			duration = (travelDistance / (UIScreen.main.bounds.height / 2)) * self.animationDuration
		} else if abs(velocity) > 1000 {
			duration = travelDistance / velocity
		}

		self.constrainCurtain(top: nearestY)
		self.currentRatio = magenticRatio

		self.willAnimateMagneticScroll?(oldRatio, magenticRatio, duration)
		self.isAnimating = true

		let shouldMimickFullscreen = (nearestY == 0) && self.mimicksFullscreenWhenExpanded
		self.contentTopConstraint.constant = shouldMimickFullscreen ? 0 : self.contentInset.top

		self.setNeedsLayout()
		
		UIView.animate(withDuration: duration, animations: {
			self.layoutIfNeeded()
			self.animateAlongsideMagneticScroll?(oldRatio, magenticRatio, duration)
			self.toggleFullscreenStateIfNeeded()
		}, completion: { _ in
			self.isAnimating = false
			self.didAnimateMagneticScroll?(oldRatio, magenticRatio)
		})
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()

		self.setNeedsLayout()
		self.layoutIfNeeded()

		let selfHeight = self.bounds.height
		self.curtainTopConstraint.constant = selfHeight

		self.setNeedsLayout()
		self.layoutIfNeeded()

		delay(0) {
			self.scrollTo(ratio: self.initialRatio, animated: self.animatedMoveToWindow)

			self.setNeedsLayout()
			self.layoutIfNeeded()

			(self.curtain as? CurtainContentView)?.onLayoutSubviews = { [weak self] in
				guard let self = self else { return }

				self.curtain.setNeedsLayout()
				self.curtain.layoutIfNeeded()

				delay(0) {
					self.scrollTo(ratio: self.currentRatio, animated: self.animatedMoveToWindow)
				}
			}
		}
	}
}
