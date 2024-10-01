import UIKit

extension UICollectionView {
    func register<T: UICollectionViewCell>(cellClass: T.Type) where T: Reusable {
        register(T.self, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }

    func register<T: UICollectionReusableView>(
        viewClass: T.Type,
        forSupplementaryViewOfKind kind: String
    ) where T: Reusable {
        register(
            T.self,
            forSupplementaryViewOfKind: kind,
            withReuseIdentifier: T.defaultReuseIdentifier
        )
    }

    func dequeueReusableCell<T: UICollectionViewCell>(
        for indexPath: IndexPath
    ) -> T where T: Reusable {
        guard let cell = dequeueReusableCell(
            withReuseIdentifier: T.defaultReuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }

        return cell
    }

    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(
        ofKind kind: String,
        for indexPath: IndexPath
    ) -> T where T: Reusable {
        guard let view = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: T.defaultReuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError(
                "Could not dequeue supplementary view" +
                        "with identifier: \(T.defaultReuseIdentifier)"
            )
        }

        return view
    }
}

extension UITableView {
	public func reloadDataAndKeepOffset() {
		// stop scrolling
		setContentOffset(contentOffset, animated: false)

		// calculate the offset and reloadData
		let beforeContentSize = contentSize
		reloadData()
		layoutIfNeeded()
		let afterContentSize = contentSize

		// reset the contentOffset after data is updated
		let newOffset = CGPoint(
			x: contentOffset.x + (afterContentSize.width - beforeContentSize.width),
			y: contentOffset.y + (afterContentSize.height - beforeContentSize.height))
		
		setContentOffset(newOffset, animated: false)
	}
}

extension UITableView {
	func register<T: UITableViewCell>(cellClass: T.Type) where T: Reusable {
		register(T.self, forCellReuseIdentifier: T.defaultReuseIdentifier)
	}

	func dequeueReusableCell<T: UITableViewCell>(
		for indexPath: IndexPath
	) -> T where T: Reusable {
		guard let cell = dequeueReusableCell(
			withIdentifier: T.defaultReuseIdentifier,
			for: indexPath
		) as? T else {
			fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
		}

		return cell
	}

	func dequeueReusableHeaderFooterView<T: UIView>() -> T? where T: Reusable {
		self.dequeueReusableHeaderFooterView(withIdentifier: T.defaultReuseIdentifier) as? T
	}

	func register<T: Reusable>(headerFooterClass: T.Type) {
		self.register(headerFooterClass, forHeaderFooterViewReuseIdentifier: headerFooterClass.defaultReuseIdentifier)
	}
}

extension UICollectionView {
	func reloadKeepingOffsetX(animated: Bool = false) {
		let offset = self.contentOffset

		self.reloadData()
		self.setNeedsLayout()
		self.layoutIfNeeded()

		onMain {
			var offset = offset
			let left = -self.contentInset.left
			let right = self.contentInset.right
			offset.x = max(left, min(offset.x, self.contentSize.width - self.bounds.width + right))

			self.setContentOffset(offset, animated: animated)
		}
	}
}
