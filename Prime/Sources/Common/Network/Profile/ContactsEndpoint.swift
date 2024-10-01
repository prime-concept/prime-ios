import Alamofire
import Foundation
import PromiseKit

protocol ContactsEndpointProtocol {
    func getContacts() -> EndpointResponse<Contacts>
    func getPhones() -> EndpointResponse<Phones>
    func getEmails() -> EndpointResponse<Emails>
    func getAddresses() -> EndpointResponse<Addresses>
    func getPhone(with id: ContactID) -> EndpointResponse<Phone>
    func getEmail(with id: ContactID) -> EndpointResponse<Email>
    func getAddress(with id: ContactID) -> EndpointResponse<Address>
    func getPhoneTypes() -> EndpointResponse<PhoneTypes>
    func getEmailTypes() -> EndpointResponse<EmailTypes>
    func getAddressTypes() -> EndpointResponse<AddressTypes>
    func getCities() -> EndpointResponse<Cities>
    func getCountries() -> EndpointResponse<Countries>
    func addOrEditPhone(
        with params: [String: Any],
        mode: ContactAdditionMode,
        id: ContactID?
    ) -> EndpointResponse<Phone>
    func addOrEditEmail(
        with params: [String: Any],
        mode: ContactAdditionMode,
        id: ContactID?
    ) -> EndpointResponse<Email>
    func addOrEditAddress(
        with params: [String: Any],
        mode: ContactAdditionMode,
        id: ContactID?
    ) -> EndpointResponse<Address>
    func delete(with id: ContactID, type: ContactsListType) -> EndpointResponse<EmptyResponse>
}

final class ContactsEndpoint: PrimeListsEndpoint, ContactsEndpointProtocol {
    private static let contactsEndpoint = "/me/contacts"
    private static let phonesEndpoint = "/me/phones"
    private static let emailsEndpoint = "/me/emails"
    private static let addressesEndpoint = "/me/address"
    private static let phoneTypesEndpoint = "/dict/phoneTypes"
    private static let emailTypesEndpoint = "/dict/emailTypes"
    private static let addressTypesEndpoint = "/dict/AddressTypes"
    private static let countriesEndpoint = "/dict/countries"
    private static let citiesEndpoint = "/dict/cities"

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
        self.retrieve(endpoint: Self.contactsEndpoint)
    }

    func getPhones() -> EndpointResponse<Phones> {
        self.retrieve(endpoint: Self.phonesEndpoint)
    }

    func getEmails() -> EndpointResponse<Emails> {
        self.retrieve(endpoint: Self.emailsEndpoint)
    }

    func getAddresses() -> EndpointResponse<Addresses> {
        self.retrieve(endpoint: Self.addressesEndpoint)
    }

    func getPhone(with id: Int) -> EndpointResponse<Phone> {
        self.retrieve(endpoint: Self.phonesEndpoint + "/\(id)")
    }

    func getEmail(with id: Int) -> EndpointResponse<Email> {
        self.retrieve(endpoint: Self.emailsEndpoint + "/\(id)")
    }

    func getAddress(with id: ContactID) -> EndpointResponse<Address> {
        self.retrieve(endpoint: Self.addressesEndpoint + "/\(id)")
    }

    func getPhoneTypes() -> EndpointResponse<PhoneTypes> {
        self.retrieve(endpoint: Self.phoneTypesEndpoint)
    }

    func getEmailTypes() -> EndpointResponse<EmailTypes> {
        self.retrieve(endpoint: Self.emailTypesEndpoint)
    }

    func getAddressTypes() -> EndpointResponse<AddressTypes> {
        self.retrieve(endpoint: Self.addressTypesEndpoint)
    }

    func getCities() -> EndpointResponse<Cities> {
        self.retrieve(endpoint: Self.citiesEndpoint)
    }

    func getCountries() -> EndpointResponse<Countries> {
        self.retrieve(endpoint: Self.countriesEndpoint)
    }

    func addOrEditPhone(
        with params: [String: Any],
        mode: ContactAdditionMode = .addition,
        id: ContactID? = nil
    ) -> EndpointResponse<Phone> {
        if mode == .addition {
            return self.create(
                endpoint: Self.phonesEndpoint,
                parameters: params,
                encoding: JSONEncoding.default
            )
        } else {
            guard let contactID = id else {
                return self.update(endpoint: "")
            }
            return self.update(
                endpoint: Self.phonesEndpoint + "/\(contactID)",
                parameters: params
            )
        }
    }

    func addOrEditEmail(
        with params: [String: Any],
        mode: ContactAdditionMode = .addition,
        id: ContactID? = nil
    ) -> EndpointResponse<Email> {
        if mode == .addition {
            return self.create(
                endpoint: Self.emailsEndpoint,
                parameters: params,
                encoding: JSONEncoding.default
            )
        } else {
            guard let contactID = id else {
                return self.update(endpoint: "")
            }
            return self.update(
                endpoint: Self.emailsEndpoint + "/\(contactID)",
                parameters: params
            )
        }
    }

    func addOrEditAddress(
        with params: [String: Any],
        mode: ContactAdditionMode,
        id: ContactID?
    ) -> EndpointResponse<Address> {
        if mode == .addition {
            return self.create(
                endpoint: Self.addressesEndpoint,
                parameters: params,
                encoding: JSONEncoding.default
            )
        } else {
            guard let contactID = id else {
                return self.update(endpoint: "")
            }
            return self.update(
                endpoint: Self.addressesEndpoint + "/\(contactID)",
                parameters: params
            )
        }
    }

    func delete(with id: Int, type: ContactsListType) -> EndpointResponse<EmptyResponse> {
        switch type {
        case .phone:
            return self.remove(endpoint: Self.phonesEndpoint + "/\(id)")
        case .email:
            return self.remove(endpoint: Self.emailsEndpoint + "/\(id)")
        case .address:
            return self.remove(endpoint: Self.addressesEndpoint + "/\(id)")
        }
    }
}

