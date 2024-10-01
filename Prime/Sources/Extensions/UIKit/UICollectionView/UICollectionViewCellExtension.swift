import UIKit

private var referenceKey = 0
private var referenceDebouncerKey = 0

extension UIView {
    class var reference: Self {
		let cleanupDebouncer: Debouncer! = ObjcAssociatedProperty.get(from: self, for: &referenceDebouncerKey) {
			Debouncer(timeout: 3) {
				let referenceView: Self? = nil
				let debouncer: Debouncer? = nil
				ObjcAssociatedProperty.set(referenceView, to: Self.self, for: &referenceKey)
				ObjcAssociatedProperty.set(debouncer, to: Self.self, for: &referenceDebouncerKey)
			}
		}

        if let referenceView: Self = ObjcAssociatedProperty.get(from: self, for: &referenceKey) {
			cleanupDebouncer.reset()
            return referenceView
        }

		let referenceView = Self()
		(referenceView as? UITableViewCell)?.prepareForReuse()
		(referenceView as? UICollectionViewCell)?.prepareForReuse()
		ObjcAssociatedProperty.set(referenceView, to: Self.self, for: &referenceKey)

        return referenceView
    }
}

extension UIView {
	func sizeFor(width: CGFloat) -> CGSize {
		var size = UIView.layoutFittingCompressedSize
		size.width = width

		size = self.systemLayoutSizeFitting(
			size,
			withHorizontalFittingPriority: .required,
			verticalFittingPriority: .defaultLow
		)
		return size
	}

	func sizeFor(height: CGFloat) -> CGSize {
		var size = UIView.layoutFittingCompressedSize
		size.height = height

		size = self.systemLayoutSizeFitting(
			size,
			withHorizontalFittingPriority: .defaultLow,
			verticalFittingPriority: .required
		)
		return size
	}
}
