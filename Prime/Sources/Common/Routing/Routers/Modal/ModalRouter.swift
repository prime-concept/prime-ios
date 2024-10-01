import Foundation
import UIKit

class ModalRouter: SourcelessRouter, RouterProtocol {
    private(set) var destination: UIViewController
    private(set) var source: ModalRouterSourceProtocol?

    private let belowTabsView: Bool

    init(
        source optionalSource: ModalRouterSourceProtocol? = nil,
        destination: UIViewController,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
        modalTransitionStyle: UIModalTransitionStyle = .coverVertical,
        belowTabsView: Bool = false
    ) {
        self.destination = destination
        self.destination.modalPresentationStyle = modalPresentationStyle
        self.destination.modalTransitionStyle = modalTransitionStyle

        self.belowTabsView = belowTabsView

        super.init()

        let possibleSource = self.currentNavigation?.topViewController
        if let source = optionalSource ?? possibleSource {
            self.source = source
        } else {
            self.source = self.window?.rootViewController
        }
    }

    func route() {
        self.source?.presentModal(controller: self.destination)
    }
}
