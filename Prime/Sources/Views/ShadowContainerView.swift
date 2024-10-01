import SnapKit
import UIKit

extension ShadowContainerView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var cornerRadius: CGFloat = 8

		var shadowColor = Palette.shared.shadow1
        var shadowOffset = CGSize(width: 0, height: 5)
        var shadowRadius: CGFloat = 10
    }
}

final class ShadowContainerView: UIView {
    private let appearance: Appearance

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupAppearance()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAppearance() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.layer.cornerRadius = self.appearance.cornerRadius

        self.dropShadow(
            offset: self.appearance.shadowOffset,
            radius: self.appearance.shadowRadius,
            color: self.appearance.shadowColor
        )
    }
}
