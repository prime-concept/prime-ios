import UIKit

final class PersonsAssembly: Assembly {
    private let indexToMove: Int
    private let shouldOpenInCreationMode: Bool

    init(indexToMove: Int = 0, shouldOpenInCreationMode: Bool = false) {
        self.indexToMove = indexToMove
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
    }

    func make() -> UIViewController {
        let presenter = PersonsPresenter(familyService: FamilyService.shared)
        let viewController = PersonsViewController(
            indexToMove: indexToMove,
            presenter: presenter,
            shouldOpenInCreationMode: shouldOpenInCreationMode)
        presenter.viewController = viewController
        return viewController
    }
}
