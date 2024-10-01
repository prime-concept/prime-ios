import UIKit

final class PersonDocumentsAssembly: Assembly {
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
        for tabType in DocumentTabType.allCases {
            let isChoosen = (tabType.typeIndex == indexToMove && shouldOpenInCreationMode)
            viewControllers.append(
                PersonDocumentTabTypeAssembly(
                    tabType: tabType,
                    shouldOpenInCreationMode: isChoosen,
                    personId: personId
                ).make()
            )
        }

        return DocumentsViewController(
            controllers: viewControllers,
            indexToMove: indexToMove
        )
    }
}
