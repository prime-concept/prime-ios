import UIKit

protocol HomeRouterProtocol: AnyObject {
    func openProfile()
    func dismissProfile()

    func openPromoCategory(id: Int)
    func openChat(taskID: Int, messageGuidToOpen: String?, onDismiss: @escaping () -> Void)
    func openChat(message: String?, onDismiss: @escaping () -> Void)
    func openDetailCalendar(date: Date)
    func openPayTasks()
    func openCompletedTasks()
    func openPayment(orderID: Int)
    func openRequestCreation(message: String?)
    func openFeedback(_ feedback: ActiveFeedback, existingRating: Int?)
}
