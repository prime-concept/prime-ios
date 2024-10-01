import UIKit

final class PersonDocumentEditAssembly: Assembly {
    private let type: DocumentEditAssembly.FormType
    private let personId: Int

    init(type: DocumentEditAssembly.FormType = .newPassport, personId: Int) {
        self.type = type
        self.personId = personId
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
        let presenter = PersonDocumentEditPresenter(
            view: view,
            document: document,
            allDocuments: FamilyDocumentsService.shared.documents ?? [],
            documentsService: FamilyDocumentsService.shared,
            filesService: FilesService.shared,
			permissionService: PermissionService.shared,
            formType: self.type,
            personId: self.personId
        )
        view.presenter = presenter

        return view
    }
}
