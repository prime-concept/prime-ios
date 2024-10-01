import UIKit

extension PinCodeDot {
    struct Appearance: Codable {
        var backgroundColorNormal = Palette.shared.black
        var backgroundColorSelected = Palette.shared.brandSecondary
        var backgroundColorError = Palette.shared.danger
    }
}

final class PinCodeDot: UIView {
    enum State {
        case normal
        case selected
        case error
    }

    var pinState: State = .normal {
        didSet {
            self.setItemBackground()
        }
    }
    
    private let appearance: Appearance

    init(appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func layoutSubviews() {
		super.layoutSubviews()
		self.layer.cornerRadius = self.bounds.height / 2
	}

    private func setupView() {
		self.setItemBackground()
    }
    
    private func setItemBackground() {
        switch self.pinState {
        case .normal:
            self.backgroundColorThemed = self.appearance.backgroundColorNormal
        case .selected:
            self.backgroundColorThemed = self.appearance.backgroundColorSelected
        case .error:
            self.backgroundColorThemed = self.appearance.backgroundColorError
        }
    }
}
