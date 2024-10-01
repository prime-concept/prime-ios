import Foundation
import UIKit

final class PersonContactsAssembly: Assembly {
    private let indexToMove: Int
    private let shouldOpenInCreationMode: Bool
    private let personId: Int

    init(indexToMove: Int = 0, shouldOpenInCreationMode: Bool = false, personId: Int) {
        self.indexToMove = indexToMove
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
        self.personId = personId
    }

    func make() -> UIViewController {
        var viewControllers: [UIViewController] = []
        [ContactsListType.phone, ContactsListType.email].forEach {
            let isChoosen = ($0.typeIndex == indexToMove && shouldOpenInCreationMode)
            viewControllers.append(
                PersonContactsListAssembly(
                    listType: $0,
                    shouldOpenInCreationMode: isChoosen,
                    personId: personId
                ).make()
            )
        }
        return ContactsListTabsViewController(
            controllers: viewControllers,
            indexToMove: indexToMove
        )
    }
}
