import UIKit

final class DocumentEditAssembly: Assembly {
    private let type: FormType

    init(type: FormType = .newPassport) {
        self.type = type
    }

    func make() -> UIViewController {
        let document: Document
        let canDelete: Bool

        switch type {
        case .newPassport:
            var doc = Document()
			doc.documentType = .passport
            document = doc
            canDelete = false

        case .newVisa:
            var doc = Document()
			doc.documentType = .visa
            document = doc
            canDelete = false

        case .existing(let doc):
            document = doc
            canDelete = true
        }

        let view = DocumentEditViewController(canDelete: canDelete)
        let presenter = DocumentEditPresenter(
            view: view,
            document: document,
            allDocuments: DocumentsService.shared.documents ?? [],
            documentsService: DocumentsService.shared,
            filesService: FilesService.shared,
			permissionService: PermissionService.shared,
            formType: self.type
        )
        view.presenter = presenter

        return view
    }

    enum FormType {
        case existing(Document)
        case newPassport
        case newVisa
    }
}
