import UIKit

extension StarsControl {
	struct Appearance: Codable {
		var selectedColor = Palette.shared.brandPrimary
		var deselectedColor = Palette.shared.gray2.withAlphaComponent(0.5)
	}
}

final class StarsControl: UIControl {
	private let appearance: Appearance

	private(set) var starsCount: Int
	private(set) var starsSpacing: CGFloat?

	private var emptyStarsStack: UIStackView!
	private var filledStarsStack: UIStackView!

	var minRating: Int = 1 {
		didSet {
			let oldRating = self.rating
			self.rating = clamp(self.minRating, self.rating, self.starsCount)
			self.updateStars()

			if oldRating != self.rating {
				self.sendEvents()
			}
		}
	}
	
	private(set) var rating: Int = 1

	public var onChanged: ((Int) -> Void)?

	init(
		appearance: Appearance = Theme.shared.appearance(),
		starImageEmpty: UIImage = UIImage(named: "task_feedback_image_star_empty")!,
		starImageFilled: UIImage = UIImage(named: "task_feedback_image_star_filled")!,
		starsCount: Int = 5,
		starsSpacing: CGFloat? = 5,
		currentRating: Int = 1,
		minRating: Int = 1,
        alreadyRatedStars: Int? = nil
	) {
		self.appearance = appearance

		self.starsCount = starsCount
		self.starsSpacing = starsSpacing
		self.minRating = minRating

		super.init(frame: .zero)

		self.emptyStarsStack = self.makeStarsStack(image: starImageEmpty)
		self.filledStarsStack = self.makeStarsStack(image: starImageFilled)

		self.placeSubviews()

		self.rating = clamp(self.minRating, currentRating, self.starsCount)
        
        if let alreadyRatedStars {
            self.rating = alreadyRatedStars
            self.updateStars()
            self.sendEvents()
            delay(0.1) {
                self.onChanged?(alreadyRatedStars)
            }
        }
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func sendEvents() {
		self.sendActions(for: .valueChanged)
		self.onChanged?(self.rating)
	}

	private func updateStars() {
		let filledStars = self.filledStarsStack.arrangedSubviews
		for i in 1...filledStars.count {
			let star = filledStars[i - 1]
			star.alpha = self.rating >= i ? 1 : 0
		}
	}

	private func makeStarsStack(image: UIImage) -> UIStackView {
		let stask = UIStackView { (stack: UIStackView) in
			stack.axis = .horizontal
			if let starsSpacing {
				stack.spacing = starsSpacing
			} else {
				stack.distribution = .equalSpacing
			}

			self.starsCount.times {
				let imageView = UIImageView(image: image)
				imageView.tintColorThemed = self.appearance.selectedColor
				stack.addArrangedSubview(imageView)
			}
			stack.isUserInteractionEnabled = false
		}

		return stask
	}

	private func placeSubviews() {
		[self.emptyStarsStack, self.filledStarsStack].forEach { stack in
			self.addSubview(stack)
			stack.make(.edges, .equalToSuperview)
		}

		self.filledStarsStack.arrangedSubviews.forEach{ $0.alpha = 0 }
		self.isUserInteractionEnabled = true
	}
}

extension StarsControl {
	public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		/// `X` Position of user touch within the Star View's bounds
		let xPosition = touch.location(in: self).x
		/// Calculate new selected stars based on the xPosition
		calculateNewStars(basedOn: xPosition)
		return true
	}

	public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		var xPosition = touch.location(in: self).x
		xPosition = clamp(0, xPosition, bounds.maxX)

		calculateNewStars(basedOn: xPosition)
		return true
	}

	private func calculateNewStars(basedOn position: CGFloat) {
		let selectedStars = Int(ceil(position / bounds.width * CGFloat(self.starsCount)))
		self.rating = clamp(self.minRating, selectedStars, self.starsCount)
		self.updateStars()
		self.sendEvents()
	}
}

extension Int {
	func times(_ work: (Int) -> Void) {
		for i in stride(from: 0, to: self, by: self >= 0 ? +1 : -1) {
			work(i)
		}
	}

	func times(_ work: () -> Void) {
		for _ in stride(from: 0, to: self, by: self >= 0 ? +1 : -1) {
			work()
		}
	}
}
