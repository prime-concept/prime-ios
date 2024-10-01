import UIKit

extension UIView {
	func toFront() {
		self.superview?.bringSubviewToFront(self)
	}

	func toBack() {
		self.superview?.sendSubviewToBack(self)
	}
}


private enum UIViewConvenienceKey {
	static var identifier = "identifier"
}

extension UIView {
	var identifier: String? {
		get {
			let result: String? =
			ObjcAssociatedProperty.get(from: self, for: &UIViewConvenienceKey.identifier)

			return result
		}
		set {
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &UIViewConvenienceKey.identifier
			)
		}
	}
}

extension UIView {
	func inset(_ insets: [CGFloat] = [0, 0, 0, 0], _ configuration: ((UIView) -> Void)? = nil) -> UIView {
		UIView {
			$0.addSubview(self)
			self.make(.edges, .equalToSuperview, insets)
			configuration?($0)
		}
	}

	func inset(_ configuration: (UIView) -> Void) -> UIView {
		let view = UIView {
			$0.addSubview(self)
		}

		configuration(view)

		return view
	}
}

extension UIView {
	func addSubviews(_ subviews: UIView...) {
		subviews.forEach {
			self.addSubview($0)
		}
	}

	func addSubviews(_ subviews: [UIView]) {
		subviews.forEach {
			self.addSubview($0)
		}
	}
}

extension UIView {
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}
