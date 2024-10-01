import UIKit

extension RequestCreationDefaultOverlayView {
	struct Appearance: Codable {
		var titleColor = Palette.shared.gray0
		var subtitleColor = Palette.shared.gray1
		var backgroundColor = Palette.shared.gray5
	}
}

final class RequestCreationDefaultOverlayView: ChatKeyboardDismissingView {
	struct ViewModel {
		let title: String
		let subtitle: String
	}

	private let appearance: Appearance

	private lazy var imageView = with(UIImageView()) { imageView in
		imageView.image = UIImage(named: "no_tasks_placeholder")
		imageView.make(.size, .lessThanOrEqual, [115, 115])
		imageView.contentMode = .scaleAspectFit
	}

	private lazy var titleLabel = with(UILabel()) { label in
		label.fontThemed = Palette.shared.primeFont.with(size: 16, weight: .medium)
		label.textColorThemed = self.appearance.titleColor
	}

	private lazy var subtitleLabel = with(UILabel()) { label in
		label.fontThemed = Palette.shared.primeFont.with(size: 13, weight: .regular)
		label.textColorThemed = self.appearance.subtitleColor
	}

	func update(with viewModel: ViewModel) {
		self.titleLabel.text = viewModel.title
		self.subtitleLabel.text = viewModel.subtitle
	}

	init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance

		super.init(frame: frame)
		self.setupView()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupView() {
		self.isUserInteractionEnabled = true
		self.backgroundColorThemed = self.appearance.backgroundColor
		
		let spacerTop: UIView = .vSpacer(growable: 10)
		let spacerBottom: UIView = .vSpacer(growable: 10)

		let vStack = UIStackView(.vertical)
		vStack.alignment = .center
		vStack.addArrangedSubviews(
			spacerTop,
			self.imageView,
			.vSpacer(10),
			self.titleLabel,
			.vSpacer(10),
			self.subtitleLabel,
			spacerBottom
		)
		self.addSubview(vStack)

		self.titleLabel.make(.height, .greaterThanOrEqual, ceil(self.titleLabel.font.lineHeight))
		self.subtitleLabel.make(.height, .greaterThanOrEqual, ceil(self.subtitleLabel.font.lineHeight))

		vStack.make(.edges, .equalToSuperview)
		spacerTop.make(.height, .equal, to: spacerBottom, priority: UILayoutPriority.defaultHigh)
	}
}
