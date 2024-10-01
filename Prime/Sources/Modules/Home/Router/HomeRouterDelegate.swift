import UIKit

protocol HomeRouterDelegate: AnyObject {
	var navigationController: UINavigationController? { get }
    var profileViewController: UIViewController { get }
    var eventsByDays: HomeViewModelEventsMap { get }
    func openChat(taskID: Int, messageGuidToOpen: String?, onDismiss: @escaping () -> Void)
    func unpaidOrder(withID orderID: Int) -> Order?
    func paymentDelegateDidFinish()
}
