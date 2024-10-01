import PromiseKit
import Foundation

protocol FamilyServiceProtocol: AnyObject {
    func getContacts() -> Promise<[Contact]>
    func updateContact(contact: Contact) -> Promise<Contact>
    func createContact(contact: Contact) -> Promise<Contact>
    func removeContact(with id: Int) -> Promise<Void>
    func getContactTypes() -> Promise<[ContactType]>
    
    func subscribeForUpdates(receiver: AnyObject, _ handler: @escaping ([Contact]) -> Void)
    func unsubscribeFromUpdates(receiver: AnyObject)
}

final class FamilyService: FamilyServiceProtocol {
	// Оставляем shared, но очищаем хранимые данные при разлогине/очистке кэша
    static let shared = FamilyService(endpoint: FamilyEndpoint(authService: LocalAuthService.shared))

    private let endpoint: FamilyEndpointProtocol
    
    private(set) var familyMembers: [Contact]?
    private(set) var contactTypes: [ContactType]?
    private var subscribers: [ObjectIdentifier: ([Contact]) -> Void] = [:]
    
    init(endpoint: FamilyEndpointProtocol) {
        self.endpoint = endpoint

		Notification.onReceive(.loggedOut) { [weak self] _ in
			self?.familyMembers = nil
			self?.contactTypes = nil
			self?.subscribers = [:]
		}

		Notification.onReceive(.shouldClearCache) { [weak self] _ in
			self?.familyMembers = nil
			self?.contactTypes = nil
		}
    }
    
    func subscribeForUpdates(receiver: AnyObject, _ handler: @escaping ([Contact]) -> Void) {
        self.subscribers[ObjectIdentifier(receiver)] = handler
    }

    func unsubscribeFromUpdates(receiver: AnyObject) {
        self.subscribers.removeValue(forKey: ObjectIdentifier(receiver))
    }
    
    func getContacts() -> Promise<[Contact]> {
        DispatchQueue.global().promise {
            self.endpoint.getContacts().promise
        }
        .map(\.data)
        .map { $0 ?? [] }
        .get { [weak self] in
            self?.familyMembers = $0
            self?.notify()
        }
    }
    
    func updateContact(contact: Contact) -> Promise<Contact> {
        guard let id = contact.id else {
			return .init(error: Endpoint.Error(.requestRejected, details: "Invalid Contact ID"))
        }
        
        return DispatchQueue.global().promise {
            self.endpoint.updateContact(id: id, contact: contact).promise
        }
        .get { [weak self] contact in
            var familyMembers = self?.familyMembers ?? []
            if let index = familyMembers.firstIndex(where: { $0.id == id }) {
                familyMembers[index] = contact
            }
            self?.familyMembers = familyMembers
            self?.notify()
        }
    }
    
    func createContact(contact: Contact) -> Promise<Contact> {
        DispatchQueue.global().promise {
            self.endpoint.createContact(contact: contact).promise
        }
        .get { [weak self] contact in
            var familyMembers = self?.familyMembers ?? []
            familyMembers.append(contact)
            
            self?.familyMembers = familyMembers
            self?.notify()
        }
    }
    
    func removeContact(with id: Int) -> Promise<Void> {
        DispatchQueue.global().promise {
            self.endpoint.removeContact(with: id).promise
        }
        .map { _ in () }
        .get { [weak self] in
            let familyMembers = self?.familyMembers ?? []
            self?.familyMembers = familyMembers.filter { $0.id != id}
            self?.notify()
        }
    }
    
    func getContactTypes() -> Promise<[ContactType]> {
        DispatchQueue.global().promise {
            self.endpoint.getContactTypes().promise
        }
        .map(\.data)
        .get(on: .main) { [weak self] types in
            self?.contactTypes = types
        }
    }
    
    private func notify() {
        guard let familyMembers = self.familyMembers else {
            return
        }

        self.subscribers.forEach { $0.value(familyMembers) }
    }
}
