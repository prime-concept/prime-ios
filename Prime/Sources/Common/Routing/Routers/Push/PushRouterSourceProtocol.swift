import Foundation
import UIKit

protocol PushRouterSourceProtocol {
    func push(module: UIViewController)
	func pop()
}

extension UIViewController: PushRouterSourceProtocol {
    @objc
    func push(module: UIViewController) {
        self.navigationController?.pushViewController(module, animated: true)
    }

	@objc
	func pop() {
		self.navigationController?.popViewController(animated: true)
	}
}
