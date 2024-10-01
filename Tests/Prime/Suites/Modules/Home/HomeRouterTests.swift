@testable import Prime

import XCTest

final class HomeRouterTests: XCTestCase {
    
    private var router: HomeRouter!
    private var viewController: UIViewController?
    private var analyticsReporter: AnalyticsReportingServiceProtocolMock!
    private var delegate: HomeRouterDelegateMock!
    
    override func setUpWithError() throws {
        viewController = UIViewController()
        analyticsReporter = AnalyticsReportingServiceProtocolMock()
        delegate = HomeRouterDelegateMock()
        
        router = HomeRouter(
            viewController: viewController,
            analyticsReporter: analyticsReporter,
            deeplinkService: DeeplinkService()
        )
        router.delegate = delegate
    }
    
    func test_openPromoCategoryID() {
        router.openPromoCategory(id: 68)
        
        XCTAssertEqual(analyticsReporter.didSelectPromoCategory_invocationCount, 1)
		let first = analyticsReporter.didSelectPromoCategory_categoryNames.first?.lowercased()
		let passes = first == "animals" || first == "животные"
        XCTAssertTrue(passes, "\(first ?? "") must be equal to Animals or Животные")
    }
    
    func test_openChatTaskID() {
        router.openChat(taskID: 123, messageGuidToOpen: nil) { }
        
        XCTAssertEqual(delegate.openChatTaskIDMessageGuidToOpenOnDismiss_invocationCount, 1)
    }
    
    func test_openDetailCalendarDate() {
        delegate.eventsByDays_returnValue = .init()
        
        router.openDetailCalendar(date: Date())
        
        XCTAssertEqual(analyticsReporter.expandedCalendar_invocationCount, 1)
    }
    
    func test_openPayTasks() {
        router.openPayTasks()
        
        XCTAssertEqual(analyticsReporter.openedModalType_invocationCount, 1)
        XCTAssertEqual(analyticsReporter.openedModalType_types.first, .waitingForPayment)
    }
    
    func test_openCompletedTasks() {
        router.openCompletedTasks()
        
        XCTAssertEqual(analyticsReporter.openedModalType_invocationCount, 1)
        XCTAssertEqual(analyticsReporter.openedModalType_types.first, .completed)
    }
    
    func test_openPaymentOrderID() {
        let order = Order(
            amount: "123_456",
            currency: "CURRENCY",
            dueDate: "2099-12-31 23:59:59",
            id: 123,
            paymentLink: URL(string: "https://example.com/"),
            orderStatus: "1"
        )
        delegate.unpaidOrderWithID_returnValue = order
        
        router.openPayment(orderID: order.id)
        
        XCTAssertEqual(analyticsReporter.tappedPayment_invocationCount, 1)
    }
}
