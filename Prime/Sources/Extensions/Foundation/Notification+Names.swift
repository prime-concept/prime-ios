import Foundation

extension Notification.Name {
    static let newTaskCreated = Notification.Name("newTaskCreated")
	static let tasksDidLoad = Notification.Name("tasksDidLoad")
	static let orderPaymentRequested = Notification.Name("orderPaymentRequested")
    static let tasksUpdateRequested = Notification.Name("tasksUpdateRequested")
	static let taskWasUpdated = Notification.Name("taskWasUpdated")
    static let taskWasSuccessfullyPersisted = Notification.Name("taskWasSuccessfullyPersisted")
}

extension Notification.Name {
	func post() {
		NotificationCenter.default.post(name: self, object: nil)
	}
}
