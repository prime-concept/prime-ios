import UIKit

extension DebugUtils {
	func alert(
		title: String = "",
		message: String,
		clipTo length: Int = 280,
		showSettings: Bool = Config.isDebugEnabled,
		action: String,
		onAction: (()-> Void)? = nil)
	{
		onMain {
			func present(_ alert: UIAlertController) {
				let rootVC = UIWindow.keyWindow?.rootViewController
				(rootVC?.topmostPresentedOrSelf).some {
					$0.present(alert, animated: true, completion: nil)
				}
			}

			var message = message
			let shouldAddEllipsis = message.count > length
			if shouldAddEllipsis {
				message = String(message.prefix(length))
			}

			let alert = UIAlertController(title: title,
										  message: message,
										  preferredStyle: .alert)
			alert.addAction(.init(title: action, style: .cancel) { _ in
				onAction?()
			})

			if showSettings {
				alert.addAction(.init(title: "🪲Настройки", style: .default) { _ in
					let debugMenu = DebugMenuViewController()
					let rootVC = UIWindow.keyWindow?.rootViewController?.topmostPresentedOrSelf
					rootVC?.present(debugMenu, animated: true, completion: nil)
				})
			}

			present(alert)
		}
	}

	func shareLog(completion: (() -> Void)? = nil) {
		guard let path = self.logFilePath else {
			return
		}

		onMain {
			let activityItems = [URL(fileURLWithPath: path)]

			let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
			activity.excludedActivityTypes = [.assignToContact, .postToTwitter]
			activity.completionWithItemsHandler = { _, _, _, _ in
				try? FileManager.default.removeItem(atPath: path)
				completion?()
			}

			UIViewController.topmostPresented?.present(activity, animated: true)
		}
	}

	func alert(sender: AnyObject? = nil, _ items: Any..., separator: String = " ", terminator: String = "\n", clipTo length: Int = 280) {
		if Config.areDebugAlertsEnabled {
			let message = message(from: items, separator: separator)
			alert(message: message, clipTo: length, action: "OK", onAction: nil)
		}
		log(sender: sender, items, separator: separator, terminator: terminator)
	}
}
