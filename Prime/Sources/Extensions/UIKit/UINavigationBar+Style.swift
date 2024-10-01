import UIKit

extension UINavigationBar {
    func applyStyle() {
        self.isTranslucent = true
        self.backgroundColorThemed = Palette.shared.gray5
        self.barTintColorThemed = Palette.shared.gray5
        self.tintColorThemed = Palette.shared.gray0
        self.titleTextAttributes = [
            .font: Palette.shared.primeFont.with(size: 16),
            .foregroundColor: Palette.shared.gray0
        ]

        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()

        let barButtonAppearance = UIBarButtonItem.appearance(
            whenContainedInInstancesOf: [UINavigationBar.self]
        )
        barButtonAppearance.setTitleTextAttributes(
            [.font: Palette.shared.primeFont.with(size: 16)],
            for: .normal
        )
        barButtonAppearance.setTitleTextAttributes(
            [.font: Palette.shared.primeFont.with(size: 16)],
            for: .highlighted
        )
    }

    func applyAuthStyle() {
        self.isTranslucent = false
        self.backgroundColorThemed = Palette.shared.gray0
        self.barTintColorThemed = Palette.shared.gray0
        self.tintColorThemed = Palette.shared.gray5

        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()
    }
}
