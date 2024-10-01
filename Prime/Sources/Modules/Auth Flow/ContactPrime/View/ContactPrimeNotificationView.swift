import UIKit

class ContactPrimeNotificationView: UIView {
	struct Appearance: Codable {
		var tintColor = Palette.shared.gray5
		var titleFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
		var messageFont = Palette.shared.primeFont.with(size: 13)
	}

	struct ViewModel {
		let iconName: String
		let title: String
		let message: String
	}

	private let appearance: Appearance

	var onClose: (() -> Void)?

	init(appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance

		super.init(frame: .zero)

		self.placeSubviews()

		self.layer.cornerRadius = 15
		self.layer.masksToBounds = true
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private lazy var imageView = with(UIImageView()) {
		$0.make(.size, .equal, [44, 44])
		$0.tintColorThemed = self.appearance.tintColor
	}

	private lazy var titleLabel = with(UILabel()) { label in
		label.numberOfLines = 1
		label.lineBreakMode = .byTruncatingTail
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.tintColor
	}

	private lazy var messageLabel = with(UILabel()) { label in
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		label.fontThemed = self.appearance.messageFont
		label.textColorThemed = self.appearance.tintColor
	}

	private lazy var closingControl = with(BlurringContainer(with: UIView())) { blur in
		blur.contentView.make(.size, .equal, [32, 32])

		blur.contentView.layer.cornerRadius = 16
		blur.contentView.layer.masksToBounds = true

		blur.alignCornerRadiiToContent()

		let imageView = UIImageView(image: UIImage(named: "onboard-info-close"))
		imageView.tintColorThemed = self.appearance.tintColor

		blur.contentView.addSubview(imageView)

		imageView.make(.center, .equalToSuperview)

		blur.addTapHandler { [weak self] in
			self?.onClose?()
		}
	}

	private func placeSubviews() {
		let contentView = UIView()

		let blurContainer = BlurringContainer(with: contentView, insets: .tlbr(13, 10, 13, 11))
		self.addSubview(blurContainer)
		blurContainer.make(.edges, .equalToSuperview)

		contentView.addSubview(self.imageView)

		let textStack = UIStackView.vertical(
			self.titleLabel,
			.vSpacer(2),
			self.messageLabel
		)
		contentView.addSubview(textStack)
		contentView.addSubview(self.closingControl)

		self.imageView.make([.leading, .centerY], .equalToSuperview)
		textStack.make(.vEdges, .equalToSuperview)
		textStack.make(.leading, .equal, to: .trailing, of: self.imageView, 5)

		self.closingControl.make([.trailing, .centerY], .equalToSuperview)
		self.closingControl.make(.leading, .equal, to: .trailing, of: textStack, +11)
	}

	func update(with viewModel: ViewModel) {
		self.imageView.image = UIImage(named: viewModel.iconName)
		self.titleLabel.attributedText = viewModel.title.attributed().string()
		self.messageLabel.attributedText = viewModel.message.attributed().lineHeight(16).string()
	}
}
