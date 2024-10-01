import UIKit

extension PrimeButton {
    struct Appearance: Codable {
		var backgroundColorThemed = Palette.shared.clear
        var backgroundColorThemedHighlited = Palette.shared.brandPrimary

        var buttonBorderColor = Palette.shared.brandSecondary
    }
}

final class PrimeButton: UIButton {
    private let appearance: Appearance

	var isInverted: Bool = false {
		didSet {
			self.setup()
		}
	}

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setup()
    }

    func setup() {
		self.clipsToBounds = true
		self.layer.cornerRadius = 8
		self.layer.borderWidth = 0.5

		self.layer.borderColorThemed = self.appearance.backgroundColorThemedHighlited

		let normalColor = self.isInverted
			? self.appearance.backgroundColorThemedHighlited
			: self.appearance.backgroundColorThemed

		let highlightedColor = self.isInverted
			? self.appearance.backgroundColorThemed
			: self.appearance.backgroundColorThemedHighlited

		self.setBackgroundColor(normalColor, for: .normal)
		self.setBackgroundColor(highlightedColor, for: .selected)
		self.setBackgroundColor(highlightedColor, for: .highlighted)
    }
}
