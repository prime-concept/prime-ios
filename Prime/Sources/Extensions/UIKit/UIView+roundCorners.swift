import UIKit

extension UIView {
    func roundCorners(corners: UIRectCorner, cornerRadius: Double) {
        let path = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: cornerRadius,
                height: cornerRadius
            )
        )
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
}
