import UIKit

//swiftlint:disable identifier_name
private var SimplestLoaderKey: UInt8 = 0
private var WasInteractiveKey: UInt8 = 0
//swiftlint:enable identifier_name

extension UIView {
	private var loader: UIView? {
		get {
			ObjcAssociatedProperty.get(
				from: self,
				for: &SimplestLoaderKey
			)
		}
		set {
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &SimplestLoaderKey
			)
		}
	}

	private var wasInteractive: Bool {
		get {
			ObjcAssociatedProperty.get(
				from: self,
				for: &WasInteractiveKey
			) ?? self.isUserInteractionEnabled
		}
		set {
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &WasInteractiveKey
			)
		}
	}

	func showSimplestLoader(offset: CGPoint = .zero) {
		self.hideSimplestLoader()

		self.wasInteractive = self.isUserInteractionEnabled
		self.isUserInteractionEnabled = false
		let loader = UIActivityIndicatorView(style: .gray)
		self.addSubview(loader)
		loader.translatesAutoresizingMaskIntoConstraints = false
		loader.make([.width, .height, .centerX, .centerY], .equalToSuperview, [0, 0, offset.x, offset.y])
		loader.startAnimating()
		self.loader = loader
	}

	func hideSimplestLoader() {
		self.loader?.removeFromSuperview()
		self.loader = nil
		self.isUserInteractionEnabled = self.wasInteractive
	}

	@discardableResult
	func showLoadingIndicator(
		isUserInteractionEnabled: Bool = false,
		dismissesOnTap: Bool = false,
		needsPad: Bool = false,
		offset: CGPoint = .zero
	) -> UIView? {
		HUD.show(
			on: self,
			mode: .spinner(needsPad: needsPad),
			offset: offset,
			isUserInteractionEnabled: isUserInteractionEnabled,
			dismissesOnTap: dismissesOnTap
		)
	}

	@discardableResult
	func showSuccessIndicator(isUserInteractionEnabled: Bool = false, needsPad: Bool = true) -> UIView? {
		let hud = HUD.show(on: self, mode: .success(needsPad: needsPad), isUserInteractionEnabled: isUserInteractionEnabled)

		delay(2) { hud?.remove() }
		return hud
	}

	@discardableResult
	func showFailureIndicator(isUserInteractionEnabled: Bool = false, needsPad: Bool = true) -> UIView? {
		let hud = HUD.show(on: self, mode: .failure(needsPad: needsPad), isUserInteractionEnabled: isUserInteractionEnabled)

		delay(2) { hud?.remove() }
		return hud
	}

	func hideLoadingIndicator(_ completion: (() -> Void)? = nil) {
		HUD.find(on: self)?.remove {
			completion?()
		}
	}
}

extension UIViewController {
	@discardableResult
	func showLoadingIndicator(
		isUserInteractionEnabled: Bool = false, 
		dismissesOnTap: Bool = false,
		needsPad: Bool = false
	) -> UIView? {
		self.view.showLoadingIndicator(
			isUserInteractionEnabled: isUserInteractionEnabled,
			dismissesOnTap: dismissesOnTap,
			needsPad: needsPad
		)
	}

	@discardableResult
	func showSuccessIndicator(isUserInteractionEnabled: Bool = false) -> UIView? {
		self.view.showSuccessIndicator(isUserInteractionEnabled: isUserInteractionEnabled)
	}

	@discardableResult
	func showFailureIndicator(isUserInteractionEnabled: Bool = false) -> UIView? {
		self.view.showFailureIndicator(isUserInteractionEnabled: isUserInteractionEnabled)
	}

	func hideLoadingIndicator(_ completion: (() -> Void)? = nil) {
		self.view.hideLoadingIndicator(completion)
	}

	func showSimplestLoader() {
		self.view.showSimplestLoader()
	}

	func hideSimplestLoader() {
		self.view.hideSimplestLoader()
	}
}
