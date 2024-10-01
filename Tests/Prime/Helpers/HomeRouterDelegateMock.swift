@testable import Prime

import UIKit

final class HomeRouterDelegateMock {
    
    var navigationController_invocationCount = 0
    var navigationController_returnValue: UINavigationController!
    
    var profileViewController_invocationCount = 0
    var profileViewController_returnValue: UIViewController!
    
    var eventsByDays_invocationCount = 0
    var eventsByDays_returnValue: HomeViewModelEventsMap!
    
    var openChatTaskIDMessageGuidToOpenOnDismiss_invocationCount = 0
    var openChatTaskIDMessageGuidToOpenOnDismiss_taskIDs = [Int]()
    var openChatTaskIDMessageGuidToOpenOnDismiss_messageGuids = [String?]()
    
    var unpaidOrderWithID_invocationCount = 0
    var unpaidOrderWithID_returnValue: Order?
    
    var paymentDelegateDidFinish_invocationCount = 0
    
}

extension HomeRouterDelegateMock: HomeRouterDelegate {
    
    var navigationController: UINavigationController? {
        navigationController_invocationCount += 1
        return navigationController_returnValue
    }
    
    var profileViewController: UIViewController {
        profileViewController_invocationCount += 1
        return profileViewController_returnValue
    }
    
    var eventsByDays: HomeViewModelEventsMap {
        eventsByDays_invocationCount += 1
        return eventsByDays_returnValue
    }
    
    func openChat(taskID: Int, messageGuidToOpen: String?, onDismiss: @escaping () -> Void) {
        openChatTaskIDMessageGuidToOpenOnDismiss_invocationCount += 1
        openChatTaskIDMessageGuidToOpenOnDismiss_taskIDs.append(taskID)
        openChatTaskIDMessageGuidToOpenOnDismiss_messageGuids.append(messageGuidToOpen)
    }
    
    func unpaidOrder(withID orderID: Int) -> Order? {
        unpaidOrderWithID_invocationCount += 1
        return unpaidOrderWithID_returnValue
    }
    
    func paymentDelegateDidFinish() {
        paymentDelegateDidFinish_invocationCount += 1
    }
    
}
