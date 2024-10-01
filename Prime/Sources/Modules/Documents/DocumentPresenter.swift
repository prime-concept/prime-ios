import Foundation
import PromiseKit

protocol DocumentPresenterProtocol: AnyObject {
    func loadDocuments()
    func openForm(documentIndex: Int)
    func retrievePersonID() -> Int?
}

final class DocumentPresenter: DocumentPresenterProtocol {
    
    weak var viewController: DocumentViewControllerProtocol?

    private let tabType: DocumentTabType
    private let documentsService: DocumentsServiceProtocol

    private var documents: [Document]?

    init(documentsService: DocumentsServiceProtocol, tabType: DocumentTabType) {
        self.documentsService = documentsService
        self.tabType = tabType

        documentsService.subscribeForUpdates(receiver: self) { [weak self] updatedDocuments in
            self?.updateDocuments(updatedDocuments)
        }
    }

    deinit {
        self.documentsService.unsubscribeFromUpdates(receiver: self)
    }

    func loadDocuments() {
        self.viewController?.showActivity()

        DispatchQueue.global().promise {
            self.documentsService.get()
        }
        .done { [weak self] docs in
            self?.updateDocuments(docs)
        }
		.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) loadDocuments failed",
					parameters: error.asDictionary
				)
		}
    }

    func openForm(documentIndex: Int) {
        guard let document = self.documents?[safe: documentIndex] else {
            return
        }

        self.viewController?.presentForm(for: .existing(document), personId: nil)
    }

    func retrievePersonID() -> Int? {
        nil
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
