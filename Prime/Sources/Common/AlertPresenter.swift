import UIKit

final class AlertPresenter {
	private static var mayPresentAlert = true

	private static func present(_ alert: UIAlertController) {
		UIViewController.topmostPresented?.present(alert, animated: true, completion: nil)
	}

	static func alert(
		title: String? = nil,
		message: String?,
		clipTo length: Int = 280,
		actionTitle action: String,
		cancelTitle cancel: String? = nil,
		onAction: (()-> Void)? = nil,
		onCancel: (()-> Void)? = nil)
	{
		guard self.mayPresentAlert else {
			return
		}

		var message = message ?? ""
		let shouldAddEllipsis = message.count > length
		if shouldAddEllipsis {
			message = String(message.prefix(length))
		}

		let alert = UIAlertController(title: title,
									  message: message,
									  preferredStyle: .alert)

		alert.addAction(.init(title: action, style: .default) { _ in
			onAction?()
			self.mayPresentAlert = true
		})

		if let cancel = cancel {
			alert.addAction(.init(title: cancel, style: .cancel) { _ in
				onCancel?()
				self.mayPresentAlert = true
			})
		}

		self.present(alert)

		self.mayPresentAlert = false
	}

	static func alertCommonError(
		_ error: Error? = nil,
		onAction: (() -> Void)? = nil
	) {
		if (error as? NSError)?.code == 401 {
			return
		}

		let callStack = Thread.callStackSymbols.joined(separator: "\n")
		DebugUtils.shared.alert(sender: self, "COMMON ERROR DIALOG WILL BE SHOWN, CALL STACK:")
		DebugUtils.shared.alert(sender: self, callStack)

		AlertPresenter.alert(
			message: "common.error".localized,
			actionTitle: "common.ok".localized,
			onAction: onAction
		)
	}
}
