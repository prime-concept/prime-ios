import UIKit

extension FeedbackSuccessView {
	struct Appearance: Codable {
		var imageTint = Palette.shared.brandPrimary

		var titleFont = Palette.shared.title3
		var titleColor = Palette.shared.gray0

		var subtitleFont = Palette.shared.body2
		var subtitleColor = Palette.shared.gray0
	}
}

class FeedbackSuccessView: UIView {
	private let appearance: Appearance

	init(appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance

		super.init(frame: .zero)

		self.placeSubviews()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func placeSubviews() {
		self.addSubview(self.successView)
		self.successView.make(.edges, .equalToSuperview)
	}

	private(set) lazy var titleLabel = UILabel { (label: UILabel) in
		label.textAlignment = .center
		label.numberOfLines = 0
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.titleColor
	}

	private(set) lazy var subtitleLabel = UILabel { (label: UILabel) in
		label.textAlignment = .center
		label.numberOfLines = 0
		label.fontThemed = self.appearance.subtitleFont
		label.textColorThemed = self.appearance.subtitleColor
	}

	private lazy var successView = UIStackView { (stack: UIStackView) in
		stack.axis = .vertical
		stack.alignment = .center

		let topSpacer = UIView()
		let bottomSpacer = UIView()

		stack.addArrangedSubviews(
			topSpacer,
			UIImageView { (imageView: UIImageView) in
				imageView.image = UIImage(named: "task_feedback_success")
				imageView.tintColorThemed = self.appearance.imageTint
			},
			.vSpacer(30),
			self.titleLabel,
			.vSpacer(10),
			self.subtitleLabel,
			bottomSpacer
		)

		topSpacer.make(.height, .equal, to: CGFloat(202.0 / 300), of: bottomSpacer)
	}

}
