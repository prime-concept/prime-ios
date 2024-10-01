import UserNotifications

final class NotificationService: UNNotificationServiceExtension, UNUserNotificationCenterDelegate {
	private lazy var richPushesHandler = RichPushesHandler()

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
		self.richPushesHandler.didReceive(request, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
		self.richPushesHandler.serviceExtensionTimeWillExpire()
    }
}
