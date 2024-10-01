import UIKit

extension UIViewController {
	static var topmostPresented: UIViewController? {
		UIApplication.shared
			.keyWindow?
			.rootViewController?
			.topmostPresentedOrSelf
	}

	var topmostPresentedOrSelf: UIViewController {
		var result = self
		while let presented = result.presentedViewController {
			result = presented
		}
		return result
	}

	func show(animated: Bool = true, completion: (() -> Void)? = nil) {
		Self.topmostPresented?
			.present(self, animated: animated, completion: completion)
	}
}

extension UIViewController {
	convenience init(title: String = "", view: UIView) {
		self.init(nibName: nil, bundle: nil)

		self.title = title
		self.view.addSubview(view)
		view.make(.edges, .equalToSuperview)
	}
}

extension Notification.Name {
	static let viewWillAppear: Self = .init(rawValue: "ViewWillAppear")
	static let viewDidDisappear: Self = .init(rawValue: "ViewDidDisappear")
}

extension UIViewController {
	static func notifyOnViewWillAppear(){
		swizzle(
			Self.self,
			#selector(Self.viewWillAppear(_:)),
			#selector(Self.swizzled_viewWillAppear(_:))
		)
	}

	static func notifyOnViewDidDisappear(){
		swizzle(
			Self.self,
			#selector(Self.viewDidDisappear(_:)),
			#selector(Self.swizzled_viewDidDisappear(_:))
		)
	}

	@objc
	dynamic private func swizzled_viewWillAppear(_ animated: Bool) {
		self.swizzled_viewWillAppear(animated)
		NotificationCenter.default.post(
			name: .viewWillAppear,
			object: nil,
			userInfo: ["ViewController": self]
		)
	}

	@objc
	dynamic private func swizzled_viewDidDisappear(_ animated: Bool) {
		self.swizzled_viewDidDisappear(animated)
		NotificationCenter.default.post(
			name: .viewDidDisappear,
			object: nil,
			userInfo: ["ViewController": self]
		)
	}
}
