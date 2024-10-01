import Foundation
import UIKit

protocol ModalRouterSourceProtocol: UIViewController {
    func presentModal(controller: UIViewController)
}

extension UIViewController: ModalRouterSourceProtocol {
    func presentModal(controller: UIViewController) {
        present(controller, animated: true)
    }
}
