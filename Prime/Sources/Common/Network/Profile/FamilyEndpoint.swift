import Alamofire
import Foundation
import PromiseKit

protocol FamilyEndpointProtocol {
    func getContacts() -> EndpointResponse<Contacts>
    func getContact(with id: Int) -> EndpointResponse<Contact>
    func updateContact(id: Int, contact: Contact) -> EndpointResponse<Contact>
    func createContact(contact: Contact) -> EndpointResponse<Contact>
    func removeContact(with id: Int) -> EndpointResponse<EmptyResponse>
    func getContactTypes() -> EndpointResponse<ContactTypes>
}

protocol FamilyContactsEndpointProtocol {
    func getContactPhones(contactId: Int) -> EndpointResponse<Phones>
    func getContactPhone(contactId: Int, phoneId: Int) -> EndpointResponse<Phone>
    func getPhoneTypes() -> EndpointResponse<PhoneTypes>
    func getContactEmails(contactId: Int) -> EndpointResponse<Emails>
    func getContactEmail(contactId: Int, emailId: Int) -> EndpointResponse<Email>
    func getEmailTypes() -> EndpointResponse<EmailTypes>
    func addOrEditPhone(
        with params: [String: Any],
        mode: ContactAdditionMode,
        contactId: Int,
        phoneId: ContactID?
    ) -> EndpointResponse<Phone>
    func addOrEditEmail(
        with params: [String: Any],
        mode: ContactAdditionMode,
        contactId: Int,
        emailId: ContactID?
    ) -> EndpointResponse<Email>
    func delete(with id: ContactID, contactId: Int, type: ContactsListType) -> EndpointResponse<EmptyResponse>
}

protocol FamilyDocumentsEndpointProtocol {
    func getContactDocuments(contactId: Int) -> EndpointResponse<Documents>
    func getContactDocument(contactId: Int, documentId: Int) -> EndpointResponse<Document>
    func createContactDocument(contactId: Int, document: Document) -> EndpointResponse<Document>
    func updateContactDocument(contactId: Int, documentId: Int, document: Document) -> EndpointResponse<Document>
    func removeContactDocument(contactId: Int, documentId: Int) -> EndpointResponse<EmptyResponse>
    func attachVisa(contactId: Int, visaId: Int, passportId: Int) -> EndpointResponse<EmptyResponse>
}

final class FamilyEndpoint: PrimeListsEndpoint, FamilyEndpointProtocol {
    func getContactTypes() -> EndpointResponse<ContactTypes> {
        self.retrieve(
            endpoint: "/dict/contactTypes"
        )
    }
    
    private static let getFamilyContactsEndpoint = "/me/contacts?fields=emails,documents,phones"
    private let authService: LocalAuthServiceProtocol

	init(authService: LocalAuthServiceProtocol) {
		self.authService = authService
		super.init()
	}

	required init(
		basePath: String,
		requestAdapter: RequestAdapter? = nil,
		requestRetrier: RequestRetrier? = nil
	) {
		self.authService = LocalAuthService.shared
		super.init(
			basePath: basePath,
			requestAdapter: requestAdapter,
			requestRetrier: requestRetrier
		)
	}

    func getContacts() -> EndpointResponse<Contacts> {
        self.retrieve(endpoint: Self.getFamilyContactsEndpoint)
    }
    
    func getContact(with id: Int) -> EndpointResponse<Contact> {
        self.retrieve(endpoint: "/me/contacts/\(id)")
    }

    func removeContact(with id: Int) -> EndpointResponse<EmptyResponse> {
        self.remove(endpoint: "/me/contacts/\(id)")
    }

    func updateContact(id: Int, contact: Contact) -> EndpointResponse<Contact> {
        guard let data = try? JSONEncoder().encode(contact),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
			return (Promise<Contact>(error: Error(.requestRejected, details: "invalidContactEncode")), { })
        }
    
        return self.update(
            endpoint: "/me/contacts/\(id)",
            parameters: dict
        )
    }

    func createContact(contact: Contact) -> EndpointResponse<Contact> {
        guard let data = try? JSONEncoder().encode(contact),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return (Promise<Contact>(error: Error(.invalidDataEncoding)), { })
        }

        return self.create(
            endpoint: "/me/contacts",
            parameters: dict,
            encoding: JSONEncoding.default
        )
    }
}

extension FamilyEndpoint: FamilyContactsEndpointProtocol {
    func getPhoneTypes() -> EndpointResponse<PhoneTypes> {
        self.retrieve(endpoint: "/dict/phoneTypes")
    }
    
    func getContactPhones(contactId: Int) -> EndpointResponse<Phones> {
        self.retrieve(endpoint: "/me/contacts/\(contactId)/phones")
    }
    
    func getContactPhone(contactId: Int, phoneId: Int) -> EndpointResponse<Phone> {
        self.retrieve(endpoint: "/me/contacts/\(contactId)/phones/\(phoneId)")
    }

    func getEmailTypes() -> EndpointResponse<EmailTypes> {
        self.retrieve(endpoint: "/dict/emailTypes")
    }
    
    func getContactEmails(contactId: Int) -> EndpointResponse<Emails> {
        self.retrieve(endpoint: "/me/contacts/\(contactId)/emails")
    }
    
    func getContactEmail(contactId: Int, emailId: Int) -> EndpointResponse<Email> {
        self.retrieve(endpoint: "/me/contacts/\(contactId)/emails/\(emailId)")
    }

    func addOrEditPhone(
        with params: [String: Any],
        mode: ContactAdditionMode = .addition,
        contactId: Int,
        phoneId: ContactID? = nil
    ) -> EndpointResponse<Phone> {
        if mode == .addition {
            return self.create(
                endpoint: "/me/contacts/\(contactId)/phones",
                parameters: params,
                encoding: JSONEncoding.default
            )
        } else {
            guard let phoneId = phoneId else {
                return self.update(endpoint: "")
            }
            return self.update(
                endpoint: "/me/contacts/\(contactId)/phones/\(phoneId)",
                parameters: params
            )
        }
    }

    func addOrEditEmail(
        with params: [String: Any],
        mode: ContactAdditionMode = .addition,
        contactId: Int,
        emailId: ContactID? = nil
    ) -> EndpointResponse<Email> {
        if mode == .addition {
            return self.create(
                endpoint: "/me/contacts/\(contactId)/emails",
                parameters: params,
                encoding: JSONEncoding.default
            )
        } else {
            guard let emailId = emailId else {
                return self.update(endpoint: "")
            }
            return self.update(
                endpoint: "/me/contacts/\(contactId)/emails/\(emailId)",
                parameters: params
            )
        }
    }
    
    func delete(with id: Int, contactId: Int, type: ContactsListType) -> EndpointResponse<EmptyResponse> {
        if type == .phone {
            return self.remove(
                endpoint: "/me/contacts/\(contactId)/phones/\(id)"
            )
        } else {
            return self.remove(
                endpoint: "/me/contacts/\(contactId)/emails/\(id)"
            )
        }
    }
}

extension FamilyEndpoint: FamilyDocumentsEndpointProtocol {
    func getContactDocuments(contactId: Int) -> EndpointResponse<Documents> {
        self.retrieve(endpoint: "/me/contacts/\(contactId)/documents")
    }
    
    func getContactDocument(contactId: Int, documentId: Int) -> EndpointResponse<Document> {
        self.retrieve(endpoint: "/me/contacts/\(contactId)/documents/\(documentId)")
    }
    
    func createContactDocument(contactId: Int, document: Document) -> EndpointResponse<Document> {
        guard let data = try? JSONEncoder().encode(document),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
			return (Promise<Document>(error: Error(.requestRejected, details: "invalidContactEncode")), { })
        }

        return self.create(
            endpoint: "/me/contacts/\(contactId)/documents",
            parameters: dict,
            encoding: JSONEncoding.default
        )
    }
    
    func updateContactDocument(contactId: Int, documentId: Int, document: Document) -> EndpointResponse<Document> {
        guard let data = try? JSONEncoder().encode(document),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
			return (Promise<Document>(error: Error(.requestRejected, details: "invalidContactEncode")), { })
        }
    
        return self.update(
            endpoint: "/me/contacts/\(contactId)/documents/\(documentId)",
            parameters: dict
        )
    }
    
    func removeContactDocument(contactId: Int, documentId: Int) -> EndpointResponse<EmptyResponse> {
        self.remove(endpoint: "/me/contacts/\(contactId)/documents/\(documentId)")
    }
    
    func attachVisa(contactId: Int, visaId: Int, passportId: Int) -> EndpointResponse<EmptyResponse> {
        return self.create(
            endpoint: "/me/contacts/\(contactId)/documents/add_to_passport",
            parameters: [
                "documentId": "\(visaId)",
                "passportId": "\(passportId)"
            ]
        )
    }
}
