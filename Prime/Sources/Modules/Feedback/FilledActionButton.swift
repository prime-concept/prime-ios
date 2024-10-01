import UIKit

extension FilledActionButton {
	struct Appearance: Codable  {
		var titleFont = Palette.shared.smallTitle
		var titleColor = Palette.shared.gray5

		var borderColor = Palette.shared.brandPrimary
		var backgroundColor = Palette.shared.brandPrimary
		var borderWidth: CGFloat = 0.5

		var cornerRadius: CGFloat = 8
	}
}

final class FilledActionButton: UIView {
	private let appearance: Appearance

	init(appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance

		super.init(frame: .zero)

		self.customize()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private(set) lazy var titleLabel = UILabel { (label: UILabel) in
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.titleColor
		label.textAlignment = .center
	}

	var title: String? {
		get {
			self.titleLabel.text
		}
		set {
			self.titleLabel.text = newValue
		}
	}

	private func customize() {
		self.addSubview(self.titleLabel)
		self.titleLabel.make([.leading, .trailing, .centerY], .equalToSuperview, [10, -10, 0])

		self.backgroundColorThemed = self.appearance.backgroundColor

		self.layer.borderWidth = self.appearance.borderWidth
		self.layer.borderColorThemed = self.appearance.borderColor
		self.layer.cornerRadius = self.appearance.cornerRadius
	}
}
