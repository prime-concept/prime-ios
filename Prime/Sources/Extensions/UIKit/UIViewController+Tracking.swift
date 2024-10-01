import UIKit

private var trackingTitleKey = "trackingTitle"
private var didAppearKey = "didAppearKey"

extension UIViewController {
    
    private(set) static var lastShownViewControllerTitle: String?

	static func startTrackingDidAppearDidDisappear() {
		swizzle(
			Self.self,
			#selector(Self.viewDidAppear(_:)),
			#selector(Self.swizzled_track_viewDidAppear(_:))
		)

		swizzle(
			Self.self,
			#selector(Self.viewDidDisappear(_:)),
			#selector(Self.swizzled_track_viewDidDisappear(_:))
		)
	}

	@objc
	dynamic private func swizzled_track_viewDidAppear(_ animated: Bool) {
		self.swizzled_track_viewDidAppear(animated)
		self.track(event: "Screen shown")
		self.didAppearDate ??= Date()
        
        Self.lastShownViewControllerTitle = trackingTitle
	}

	@objc
	dynamic private func swizzled_track_viewDidDisappear(_ animated: Bool) {
		self.swizzled_track_viewDidDisappear(animated)

		var parameters = [String: Any]()
		if let didAppearDate = self.didAppearDate {
			let difference = Date().timeIntervalSince(didAppearDate)
			parameters["seconds"] = Int(ceil(difference))
		}

		self.didAppearDate = nil

		self.track(event: "Screen hidden", parameters: parameters)
	}

	private func track(event name: String, parameters: [String: Any] = [:]) {
		let className = "\(type(of: self))"
		if className.hasPrefix("UI") || className.hasSuffix("NavigationController") {
			return
		}

		let title = self.trackingTitle

		AnalyticsReportingService.shared.log(name: name, parameters: [title: parameters])
	}

	var didAppearDate: Date? {
		get {
			ObjcAssociatedProperty.get(from: self, for: &didAppearKey)
		}
		set {
			ObjcAssociatedProperty.set(newValue, to: self, for: &didAppearKey)
		}
	}

	var trackingTitle: String {
		get {
			let storedTitle: String? = ObjcAssociatedProperty.get(from: self, for: &trackingTitleKey)
			let className = "\(type(of: self))"
			let title = storedTitle ?? self.title

			var trackingTitle = className
			if let title = title {
				trackingTitle += " (\(title))"
			}

			return trackingTitle
		}
		set {
			ObjcAssociatedProperty.set(newValue, to: self, for: &trackingTitleKey)
		}
	}
}
