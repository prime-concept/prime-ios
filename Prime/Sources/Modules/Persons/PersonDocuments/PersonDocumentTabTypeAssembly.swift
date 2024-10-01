import UIKit

final class PersonDocumentTabTypeAssembly: Assembly {
    private let tabType: DocumentTabType
    private let shouldOpenInCreationMode: Bool
    private let personId: Int

    init(tabType: DocumentTabType, shouldOpenInCreationMode: Bool = false, personId: Int) {
        self.tabType = tabType
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
        self.personId = personId
    }

    func make() -> UIViewController {
        let presenter = PersonDocumentPresenter(
            documentsService: FamilyDocumentsService.shared,
            tabType: tabType,
            personId: personId
        )
        let viewController = DocumentViewController(
            presenter: presenter,
            tabType: tabType,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        )
        presenter.viewController = viewController
        return viewController
    }
}
