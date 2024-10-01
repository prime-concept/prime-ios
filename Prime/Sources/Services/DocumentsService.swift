import Foundation
import PromiseKit

protocol DocumentsServiceProtocol: AnyObject {
    func get() -> Promise<[Document]>
    func create(document: Document) -> Promise<Document>
    func update(document: Document) -> Promise<Document>
    func delete(with id: Int) -> Promise<Void>
    func attach(visa: Document, toPassportWithID passportID: Int) -> Promise<Void>

    func subscribeForUpdates(receiver: AnyObject, _ handler: @escaping ([Document]) -> Void)
    func unsubscribeFromUpdates(receiver: AnyObject)
}

final class DocumentsService: DocumentsServiceProtocol {
	// Оставляем shared, но очищаем хранимые данные при разлогине/очистке кэша
    static let shared = DocumentsService(endpoint: DocumentsEndpoint(authService: LocalAuthService.shared))

    private let endpoint: DocumentsEndpointProtocol

    private(set) var documents: [Document]?
    private var subscribers: [ObjectIdentifier: ([Document]) -> Void] = [:]

    init(endpoint: DocumentsEndpointProtocol) {
        self.endpoint = endpoint

		Notification.onReceive(.loggedOut) { [weak self] _ in
			self?.documents = nil
			self?.subscribers = [:]
		}

		Notification.onReceive(.shouldClearCache) { [weak self] _ in
			self?.documents = nil
		}
    }

    func subscribeForUpdates(receiver: AnyObject, _ handler: @escaping ([Document]) -> Void) {
        self.subscribers[ObjectIdentifier(receiver)] = handler
    }

    func unsubscribeFromUpdates(receiver: AnyObject) {
        self.subscribers.removeValue(forKey: ObjectIdentifier(receiver))
    }

    func get() -> Promise<[Document]> {
        DispatchQueue.global().promise {
            self.endpoint.getDocs().promise
        }
        .map(\.data)
        .map { $0 ?? [] }
        .get { [weak self] in
            self?.documents = $0
            self?.notify()
        }
    }

    func delete(with id: Int) -> Promise<Void> {
        DispatchQueue.global().promise {
            self.endpoint.removeDocument(with: id).promise
        }
        .map { _ in () }
        .get { [weak self] in
            let documents = self?.documents ?? []
            self?.documents = documents.filter { $0.id != id }
            self?.notify()
        }
    }

    func create(document: Document) -> Promise<Document> {
        DispatchQueue.global().promise {
            self.endpoint.create(document: document).promise
        }
        .get { [weak self] document in
            var documents = self?.documents ?? []
            documents.append(document)

            self?.documents = documents
            self?.notify()
        }
    }

    func update(document: Document) -> Promise<Document> {
        guard let id = document.id else {
            return .init(error: Endpoint.Error(.requestRejected, details: "Invalid ID"))
        }

        return DispatchQueue.global().promise {
            self.endpoint.update(id: id, document: document).promise
        }
        .get { [weak self] document in
            var documents = self?.documents ?? []

            for i in 0..<documents.count where documents[i].id == document.id {
                documents[i] = document
            }

            self?.documents = documents
            self?.notify()
        }
    }

    func attach(visa: Document, toPassportWithID passportID: Int) -> Promise<Void> {
        guard let id = visa.id else {
			return .init(error: Endpoint.Error(.requestRejected, details: "invalidId"))
        }

        return DispatchQueue.global().promise {
            self.endpoint.attachVisa(id: id, passportId: passportID).promise
        }
        .map { _ in () }
        .get { [weak self] in
            var documents = self?.documents ?? []

            guard let passport = documents.first(where: { $0.id == passportID }) else {
                return
            }

            for i in 0..<documents.count where documents[i].id == id {
                documents[i].relatedPassport = AttachedDocument(
                    id: passportID,
                    documentType: passport.documentType ?? .passport,
                    documentNumber: passport.documentNumber
                )
            }

            self?.documents = documents
            self?.notify()
        }
    }

    private func notify() {
        guard let documents = self.documents else {
            return
        }

        self.subscribers.forEach { $0.value(documents) }
    }
}
