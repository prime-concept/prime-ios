import Foundation
import PromiseKit

final class PersonDocumentPresenter: DocumentPresenterProtocol {
    
    weak var viewController: DocumentViewControllerProtocol?

    private let tabType: DocumentTabType
    private let documentsService: FamilyDocumentsServiceProtocol
    private let personId: Int
    
    private var documents: [Document]?

    init(documentsService: FamilyDocumentsServiceProtocol, tabType: DocumentTabType, personId: Int) {
        self.documentsService = documentsService
        self.tabType = tabType
        self.personId = personId
        
        self.documentsService.subscribeForUpdates(receiver: self) { [weak self] updatedDocuments in
            self?.updateDocuments(updatedDocuments)
        }
    }

    deinit {
        self.documentsService.unsubscribeFromUpdates(receiver: self)
    }

    func loadDocuments() {
        self.viewController?.showActivity()

        DispatchQueue.global().promise {
            self.documentsService.get(contactId: self.personId)
        }
        .done { [weak self] docs in
            self?.updateDocuments(docs)
        }
		.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) documentsService.get failed",
					parameters: error.asDictionary
				)
		}
    }

    func openForm(documentIndex: Int) {
        guard let document = self.documents?[safe: documentIndex] else {
            return
        }

        self.viewController?.presentForm(for: .existing(document), personId: self.personId)
    }
    
    func retrievePersonID() -> Int? {
        return personId
    }
    
    private func updateDocuments(_ documents: [Document]) {
        let documents = documents
            .filter {
                $0.documentType != nil &&
                $0.documentType.flatMap(self.tabType.documentTypes.contains) ?? false
            }

        let viewModel = documents.map(self.tabType.viewModelFactory)

        self.documents = documents
        self.viewController?.update(with: viewModel)
    }
}
