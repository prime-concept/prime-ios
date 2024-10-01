import UIKit

// MARK: - HomeRouter

final class HomeRouter {
    
    private weak var viewController: UIViewController?
    weak var delegate: HomeRouterDelegate?
    
    private let analyticsReporter: AnalyticsReportingServiceProtocol
    private let deeplinkService: DeeplinkService
    private lazy var paymentDelegate = HomePaymentDelegate { [weak self] in
        self?.delegate?.paymentDelegateDidFinish()
    }
    
    init(
        viewController: UIViewController?,
        analyticsReporter: AnalyticsReportingServiceProtocol,
        deeplinkService: DeeplinkService
    ) {
        self.viewController = viewController
        self.analyticsReporter = analyticsReporter
        self.deeplinkService = deeplinkService
    }
}

// MARK: - HomeRouterProtocol

extension HomeRouter: HomeRouterProtocol {
    
    func openProfile() {
        guard
            let profileViewController = delegate?.profileViewController,
            let navigationController = delegate?.navigationController,
            !navigationController.viewControllers.contains(profileViewController)
        else { return }
        
        FeedbackGenerator.vibrateSelection()
        
        navigationController.pushViewController(profileViewController, animated: true)
    }

    func dismissProfile() {
        guard
            let profileViewController = delegate?.profileViewController,
            let navigationController = delegate?.navigationController,
            navigationController.viewControllers.contains(where: { $0 === profileViewController })
        else {
            return
        }

        if let viewController = navigationController.topViewController {
            viewController.dismiss(animated: true) {
                navigationController.popToRootViewController(animated: true)
            }
        }

        navigationController.popToRootViewController(animated: true)
    }

    func openPromoCategory(id: Int) {
        guard let taskType = TaskTypeEnumeration(id: id) else { return }
        
        analyticsReporter.didSelectPromoCategory(taskType.correctName)
        
        let deepLink = DeeplinkService.Deeplink.createTask(taskType)
        deeplinkService.process(deeplink: deepLink)
    }
    
    func openChat(taskID: Int, messageGuidToOpen: String?, onDismiss: @escaping () -> Void) {
        delegate?.openChat(taskID: taskID, messageGuidToOpen: messageGuidToOpen, onDismiss: onDismiss)
    }
    
    func openChat(message: String?, onDismiss: @escaping () -> Void) {
        openRequestCreation(message: message)
    }
    
    func openRequestCreation(message: String?) {
        let assembly = RequestCreationAssembly(preinstalledText: message)
        let chatViewController = assembly.make()

        let router = ModalRouter(
            source: viewController?.topmostPresentedOrSelf,
            destination: chatViewController,
            modalPresentationStyle: .formSheet
        )
        
        router.route()
    }
    
    func openDetailCalendar(date: Date) {
        guard let events = delegate?.eventsByDays else { return }
        let assembly = DetailCalendarAssembly(
            transitioningDelegate: viewController as? UIViewControllerTransitioningDelegate,
            events: events,
            date: date
        )
        let router = ModalRouter(
            source: viewController,
            destination: assembly.make(),
            modalPresentationStyle: .formSheet,
            belowTabsView: true
        )
        router.route()
        analyticsReporter.expandedCalendar()
    }
    
    func openPayTasks() {
        let router = ModalRouter(
            source: viewController,
            destination: TasksTabViewController(type: .pay),
            modalPresentationStyle: .pageSheet
        )
        router.route()
        analyticsReporter.openedModal(type: .waitingForPayment)
    }
    
    func openCompletedTasks() {
        let tasksTabController = TasksTabViewController(type: .completed)
        let router = ModalRouter(
            source: viewController,
            destination: tasksTabController,
            modalPresentationStyle: .pageSheet
        )
        router.route()
        self.analyticsReporter.openedModal(type: .completed)
        self.deeplinkService.clearAction(.tasksCompleted)
    }
    
    func openPayment(orderID: Int) {
        guard let order = delegate?.unpaidOrder(withID: orderID) else {
            return assertionFailure("Invalid order")
        }
        
        guard
            let paymentLink = order.paymentLink,
            let controller = viewController?.topmostPresentedOrSelf
        else {
            let message = "No payment link for Order: \(order.id)"
            if !Config.isProdEnabled {
                DebugUtils.shared.alert(message)
            } else {
                fatalError(message)
            }
            return
        }
        
        let router = SafariRouter(
            url: paymentLink,
            source: controller,
            delegate: paymentDelegate
        )
        router.route()
        analyticsReporter.tappedPayment()
    }
    
    func openFeedback(_ feedback: ActiveFeedback, existingRating: Int?) {
        let feedbackViewController = FeedbackAssembly(
            feedback: feedback,
            alreadyRatedStars: existingRating
        ).makeModule()
        viewController?.topmostPresentedOrSelf.present(feedbackViewController, animated: true)
    }
}
