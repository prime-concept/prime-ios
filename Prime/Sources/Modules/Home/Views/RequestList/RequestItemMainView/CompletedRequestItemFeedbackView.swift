import UIKit

final class CompletedRequestItemFeedbackView: UIView, RequestItemFeedbackView {
	struct Appearance: Codable {
		var tintColor = Palette.shared.brandSecondary

		var titleFont = Palette.shared.caption
		var titleColor = Palette.shared.titles

		var backgroundColor = Palette.shared.gray5
		var foregroundColor = Palette.shared.brandSecondary.withAlphaComponent(0.05)
	}
	
	private let appearance: Appearance
	private lazy var titleLabel = UILabel { (label: UILabel) in
		label.adjustsFontSizeToFitWidth = true
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.titleColor
		label.textAlignment = .center
	}

	private lazy var stars: [UIImageView] = (0..<5).map { _ in
		let imageView = UIImageView(image: UIImage(named: "task_feedback_image_star_empty"))
		imageView.make(.size, .equal, [34, 34])
		imageView.tintColorThemed = self.appearance.tintColor
		return imageView
	}

	private lazy var starsControl: UIStackView = {
		let stack = UIStackView.horizontal(self.stars)
		stack.distribution = .equalSpacing

		return stack
	}()

	init(frame: CGRect = .zero, appearance: Appearance = .init()) {
		self.appearance = appearance
		super.init(frame: frame)
		self.placeSubviews()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func placeSubviews() {
		let background = UIView { $0.backgroundColorThemed = self.appearance.backgroundColor }
		let foreground = UIView { $0.backgroundColorThemed = self.appearance.foregroundColor }

		self.addSubviews(
			background,
			foreground,
			self.titleLabel,
			self.starsControl
		)

		background.make(.edges, .equalToSuperview)
		foreground.make(.edges, .equalToSuperview)

		self.titleLabel.make(.edges(except: .bottom), .equalToSuperview, [10, 10, -10])
		self.starsControl.place(under: self.titleLabel, +15)
		self.starsControl.make(.edges(except: .top), .equalToSuperview, [15, -15, -15])
	}

	func setup(with viewModel: RequestItemFeedbackViewModel) {
		self.titleLabel.textThemed = viewModel.title
	}
}
