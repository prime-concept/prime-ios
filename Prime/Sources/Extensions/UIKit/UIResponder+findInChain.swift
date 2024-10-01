import UIKit

extension UIResponder {
    func findInResponderChain<T>() -> T? {
        var current: UIResponder? = self
        while current != nil {
            if current is T {
                return current as? T
            }

            current = current?.next
        }

        return nil
    }
}
