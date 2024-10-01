import UIKit

class PrimeWindow: UIWindow {
	static let main = PrimeWindow(handlesMotionEvents: true)
	static let blocking = with(PrimeWindow()) {
		$0.windowLevel = .statusBar
	}

	private let handlesMotionEvents: Bool

	init(handlesMotionEvents: Bool = false) {
		self.handlesMotionEvents = handlesMotionEvents

		super.init(frame: UIScreen.main.bounds)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		self.presentDebugMenuIfNeeded(for: motion)
	}

	private func presentDebugMenuIfNeeded(for motion: UIEvent.EventSubtype) {
		guard self.handlesMotionEvents, Config.isDebugEnabled, motion == .motionShake else {
			return
		}

		DebugMenuViewController.show()
	}
}

class PassthroughWindow: UIWindow {
	static let shared = PassthroughWindow { (window: PassthroughWindow) in
		window.frame = UIScreen.main.bounds
		window.rootViewController = UIViewController()
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		false
	}
}

extension UIWindow {
	static var keyWindow: Self? {
		UIApplication.shared.windows.filter {$0.isKeyWindow}.first as? Self
	}
}
