import UIKit

extension ExpensesNoDataView {
	struct Appearance: Codable {
		static let image = UIImage(named: "expenses_no_data")

		var backgroundColor = Palette.shared.gray5

		var titleFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
		var titleColor = Palette.shared.gray0

		var subtitleFont = Palette.shared.primeFont.with(size: 13, weight: .regular)
		var subtitleColor = Palette.shared.gray1
	}
}

final class ExpensesNoDataView: UIView {
	private let appearance: Appearance

	private lazy var mainStackView = with(UIStackView(.vertical)) { stack in
		let imageStack = UIStackView(.horizontal)
		imageStack.addArrangedSubviews(
			.hSpacer(growable: 0), self.imageView, .hSpacer(growable: 0)
		)
		imageStack.arrangedSubviews[0].make(.width, .equal, to: imageStack.arrangedSubviews[2])

		stack.addArrangedSpacer(growable: 0)
		stack.addArrangedSubviews(imageStack)
		stack.addArrangedSpacer(15)
		stack.addArrangedSubview(self.titleLabel)
		stack.addArrangedSpacer(5)
		stack.addArrangedSubview(self.subtitleLabel)
		stack.addArrangedSpacer(growable: 0)
		stack.arrangedSubviews[0].make(.height, .equal, to: stack.arrangedSubviews[6])
	}

	private lazy var imageView = with(UIImageView()) { imageView in
		imageView.contentMode = .scaleAspectFit
		imageView.image = Appearance.image
	}

	private lazy var titleLabel = with(UILabel()) { label in
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		label.textAlignment = .center
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.titleColor

		label.text = "profile.settings.expenses.noData.title".localized
	}

	private lazy var subtitleLabel = with(UILabel()) { label in
		label.numberOfLines = 0

		let text = "profile.settings.expenses.noData.subtitle".localized
		let attributedText = AttributedStringBuilder(string: text)
			.font(self.appearance.subtitleFont)
			.foregroundColor(self.appearance.subtitleColor)
			.alignment(.center)
			.lineBreakMode(.byWordWrapping)
			.lineSpacing(3)
			.string()

		label.attributedTextThemed = attributedText
	}

	init(appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance
		super.init(frame: .zero)

		self.setupView()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupView() {
		self.backgroundColorThemed = self.appearance.backgroundColor

		self.addSubview(self.mainStackView)
		self.mainStackView.make([.top, .bottom, .centerX], .equalToSuperview)
		self.mainStackView.make(.width, .equal, to: 250.0 / 375, of: self)
	}
}
