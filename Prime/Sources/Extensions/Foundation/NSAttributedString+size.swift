import Foundation
import CoreGraphics

extension NSAttributedString {
    func size(maxSize: CGSize) -> CGSize {
        if self.length == 0 {
            return .zero
        }

        return self.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, context: nil).size
    }
}
