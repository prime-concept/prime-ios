import UIKit

extension FeedbackRatingView {
	struct Appearance: Codable {
		var taskTitleColor = Palette.shared.gray0
		var taskTitleFont = Palette.shared.body2
		var taskDateColor = Palette.shared.gray1
		var taskDateFont = Palette.shared.body3
		var imageViewTint = Palette.shared.brandSecondary
	}
}

class FeedbackRatingView: UIView {
	private let appearance: Appearance
    private var imageSize = CGSize(width: 20, height: 20)
    private var alreadyRatedStars: Int?

	var onRatingSet: ((Int) -> Void)?

	var rating: Int {
		self.starsContainer.starsControl.rating
	}

    init(appearance: Appearance = Theme.shared.appearance(), alreadyRatedStars: Int? = nil) {
		self.appearance = appearance
        self.alreadyRatedStars = alreadyRatedStars
		super.init(frame: .zero)

		self.placeSubviews()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private(set) lazy var imageView = UIImageView { (imageView: UIImageView) in
		imageView.contentMode = .scaleAspectFit
        imageView.make(.size, .equal, [imageSize.width, imageSize.height])
		imageView.tintColorThemed = self.appearance.imageViewTint
	}

	private(set) lazy var imageViewContainer = self.imageView.inset { container in
		self.imageView.make(.center, .equalToSuperview)
		container.make(.size, .equal, [36, 36])
		container.layer.cornerRadius = 18
		container.layer.borderWidth = 0.5
		container.layer.borderColorThemed = self.appearance.imageViewTint
	}.inset([4, 4, -4, -4])


	private(set) lazy var taskTitleLabel = UILabel { (label: UILabel) in
		label.textColorThemed = self.appearance.taskTitleColor
		label.fontThemed = self.appearance.taskTitleFont
		label.textAlignment = .center
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
	}

	private(set) lazy var taskDateLabel = UILabel { (label: UILabel) in
		label.textColorThemed = self.appearance.taskDateColor
		label.fontThemed = self.appearance.taskDateFont
		label.textAlignment = .center
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
	}

	private func placeSubviews() {
		let vStack = UIStackView.vertical(
			self.imageViewContainer,

			UIStackView.vertical(
				self.taskTitleLabel,
				.vSpacer(5),
				self.taskDateLabel
			).inset([10, 15, -20, -15]),

			self.starsContainer
		)

		vStack.alignment = .center

		self.addSubview(vStack)
		vStack.make(.edges, .equalToSuperview)
	}

	private(set) lazy var starsContainer: FeedbackStarsContainer = {
        let container = FeedbackStarsContainer(alreadyRatedStars: alreadyRatedStars)
		container.starsControl.onChanged = { [weak self] rating in
			self?.onRatingSet?(rating)
		}
		return container
	}()
}
