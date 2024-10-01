import DeckTransition
import Foundation

final class DeckRouter: ModalRouter {
    override func route() {
        let transitionDelegate = DeckTransitioningDelegate()
        self.destination.transitioningDelegate = transitionDelegate
        self.destination.modalPresentationStyle = .custom
        self.source?.present(destination, animated: true)
    }
}
