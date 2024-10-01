import UIKit

extension LayerBackgroundView {
	struct Appearance: Codable {
		var color = Palette.shared.gray1.withAlphaComponent(0.25)
		var opacity: Float = 0.2
		var radius: CGFloat = 0
		var offset = CGSize(width: 0, height: 1)
	}
}

final class LayerBackgroundView: UIView {
	private let appearance: Appearance = Theme.shared.appearance()

    init() {
        super.init(frame: .zero)

        self.dropShadow()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func dropShadow() {
		self.layer.shadowColorThemed = self.appearance.color
		self.layer.shadowOpacity = self.appearance.opacity
		self.layer.shadowOffset = self.appearance.offset
		self.layer.shadowRadius = self.appearance.radius
        self.layer.masksToBounds = false
    }
}
