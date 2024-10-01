import UIKit

extension UINavigationBar {
    func setGradientBackground(
        to navController: UINavigationController,
        colors: [ThemedColor]
    ) {
        let gradient = CAGradientLayer()
        var bounds = navController.navigationBar.bounds
        bounds.size.height += UIApplication.shared.statusBarFrame.size.height
        gradient.frame = bounds
        gradient.colorsThemed = colors
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)

        if let image = getImageFrom(gradientLayer: gradient) {
            navController.navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
        }
    }

    func getImageFrom(gradientLayer: CAGradientLayer) -> UIImage? {
        var gradientImage: UIImage?
        UIGraphicsBeginImageContext(gradientLayer.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            gradientImage = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(
                withCapInsets: UIEdgeInsets.zero,
                resizingMode: .stretch
            )
        }
        UIGraphicsEndImageContext()
        return gradientImage
    }
}
