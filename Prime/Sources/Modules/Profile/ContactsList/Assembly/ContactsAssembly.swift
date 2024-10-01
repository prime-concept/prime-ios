import Foundation
import UIKit

final class ContactsAssembly: Assembly {
    private let indexToMove: Int
    private let shouldOpenInCreationMode: Bool

    init(indexToMove: Int = 0, shouldOpenInCreationMode: Bool = false) {
        self.indexToMove = indexToMove
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
    }

    func make() -> UIViewController {
        var viewControllers: [UIViewController] = []
        for tabType in ContactsListType.allCases {
            let isChoosen = (tabType.typeIndex == indexToMove && shouldOpenInCreationMode)
            viewControllers.append(
                ContactsListAssembly(
                    listType: tabType,
                    shouldOpenInCreationMode: isChoosen
                ).make()
            )
        }
        return ContactsListTabsViewController(
            controllers: viewControllers,
            indexToMove: indexToMove
        )
    }
}
