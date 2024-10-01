import UIKit

final class NavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.topViewController?.preferredStatusBarStyle ?? .default
    }

    override var childForStatusBarStyle: UIViewController? {
        self.topViewController
    }
}
