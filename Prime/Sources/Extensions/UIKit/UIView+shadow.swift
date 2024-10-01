import UIKit

extension UIView {
    func dropShadow(
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 6,
		color: ThemedColor = Palette.shared.black,
        opacity: Float = 0.2
    ) {
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowColorThemed = color
        self.layer.shadowOpacity = opacity
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.masksToBounds = false
    }

    func resetShadow() {
        self.layer.shadowOpacity = 0
    }
}
