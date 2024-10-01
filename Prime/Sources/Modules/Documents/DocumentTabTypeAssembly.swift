import UIKit

final class DocumentTabTypeAssembly: Assembly {
    private let tabType: DocumentTabType
    private let shouldOpenInCreationMode: Bool

    init(tabType: DocumentTabType, shouldOpenInCreationMode: Bool = false) {
        self.tabType = tabType
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
    }

    func make() -> UIViewController {
        let presenter = DocumentPresenter(
            documentsService: DocumentsService.shared,
            tabType: tabType
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
