import Foundation
import UIKit

class SourcelessRouter {
    var window: UIWindow? {
        (UIApplication.shared.delegate as? AppDelegate)?.window
    }

    var currentNavigation: UINavigationController? {
        guard let tabController = self.currentTabBarController else {
            return nil
        }

        let count = tabController.viewControllers?.count ?? 0
        let index = tabController.selectedIndex
        if index < count {
            return tabController.viewControllers?[tabController.selectedIndex] as? UINavigationController
        } else {
            return tabController.viewControllers?[0] as? UINavigationController
        }
    }

    var topController: UIViewController? {
        func findNextController(controller: UIViewController) -> UIViewController? {
            if
                let tabBarController = controller as? UITabBarController,
                let selected = tabBarController.selectedViewController
            {
                return selected
            }

            if
                let navigationController = controller as? UINavigationController,
                let top = navigationController.topViewController
            {
                return top
            }

            return controller.presentedViewController
        }

        guard
            let window = UIWindow.keyWindow,
            let rootViewController = window.rootViewController
        else {
            return nil
        }

        var topController = rootViewController

        while let newTopController = findNextController(controller: topController) {
            topController = newTopController
        }

        return topController
    }

    var currentTabBarController: UITabBarController? {
        self.window?.rootViewController as? UITabBarController
    }
}
