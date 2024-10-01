import Foundation
import PhoneNumberKit
import PromiseKit

extension Notification.Name {
    static let personContactsChanged = Notification.Name("Person.Contact.Changed")
}

final class PersonContactEditPresenter: ContactAdditionPresenterProtocol {
    private let listType: ContactsListType
    private let mode: ContactAdditionMode
    private let id: ContactID?
    private let personId: Int
    private let contactsEndpoint: FamilyContactsEndpointProtocol
    private let completion: ((Bool) -> Void)?
    private var contactTypeData: [ContactTypeViewModel] = []
    private var countries = [Country]()
    private var cities = [City]()

    private var textDict = [ContactAdditionFieldType: String]()

    private var contactType: ContactTypeViewModel?
    private var selectedCountry: Country?
    private var selectedCity: City?

    weak var controller: ContactAdditionViewControllerProtocol?

    init(
        listType: ContactsListType = .phone,
        mode: ContactAdditionMode,
        id: ContactID?,
        endpoint: FamilyContactsEndpointProtocol,
        personId: Int,
        completion: @escaping ((Bool) -> Void)
    ) {
        self.listType = listType
        self.mode = mode
        self.id = id
        self.contactsEndpoint = endpoint
        self.completion = completion
        self.personId = personId
    }

    func didLoad() {
        self.setup()
        self.getContactTypes()
    }

    func save(text: String, for key: ContactAdditionFieldType) {
        self.textDict[key] = text
    }

    func didTapOnCodeSelection() {
        let assembly = CountryCodesAssembly(countryCode: .defaultCountryCode) { code in
            var phoneCode = code.code
            if phoneCode.first != "+" {
                phoneCode = "+" + phoneCode
            }
            self.controller?.set(code: phoneCode)
        }
        let router = ModalRouter(
            source: self.controller,
            destination: assembly.make(),
            modalPresentationStyle: .pageSheet
        )
        router.route()
    }

    func didTapOnSelection(_ type: ContactAdditionFieldType) {
        switch type {
        case .type:
            let assembly = ContactTypeSelectionAssembly(data: self.contactTypeData) { [weak self] selectedType in
                self?.contactType = selectedType
                self?.controller?.set(contactType: selectedType)
            }
            self.controller?.presentTypeSelection(with: assembly.make(), scrollView: assembly.scrollView)
        case .country:
            let assembly = CountrySelectionAssembly(
                selectedCountry: self.selectedCountry
            ) { [weak self] selectedCountry in
                guard let self = self else {
                    return
                }

                self.selectedCountry = selectedCountry
                if let country = self.selectedCountry {
                    self.controller?.set(country: country)
                }
            }

            self.controller?.presentTypeSelection(with: assembly.make(), scrollView: assembly.scrollView)
        case .city:
            guard let country = self.selectedCountry else {
                self.controller?.showValidationAlert(for: .country)
                return
            }

            let assembly = CityByCountrySelectionAssembly(
                selectedCity: self.selectedCity,
                country: country
            ) { [weak self] selectedCity in
                guard let self = self else {
                    return
                }

                self.selectedCity = selectedCity
                if let city = self.selectedCity {
                    self.controller?.set(city: city)
                }
            }

            self.controller?.presentTypeSelection(with: assembly.make(), scrollView: assembly.scrollView)
        default:
            break
        }
    }

    func addOrEdit() {
        self.controller?.showActivity()

        guard let type = self.contactType else {
            self.controller?.showValidationAlert(for: .type)
            self.controller?.hideActivity()
            return
        }

        switch self.listType {
        case .phone:
            let phone = self.textDict[.phone] ?? ""

            if self.isValid(phoneNumber: phone) == false {
                self.controller?.showValidationAlert(for: .phone)
                self.controller?.hideActivity()
                return
            }
        case .email:
            let email = self.textDict[.email] ?? ""

            if self.isValid(email: email) == false {
                self.controller?.showValidationAlert(for: .email)
                self.controller?.hideActivity()
                return
            }
        case .address:
            if self.selectedCountry == nil {
                self.controller?.showValidationAlert(for: .country)
                self.controller?.hideActivity()
                return
            } else if self.selectedCity == nil {
                self.controller?.showValidationAlert(for: .city)
                self.controller?.hideActivity()
                return
            }
        }

        switch self.listType {
        case .phone:
            let phone = self.textDict[.phone] ?? ""
            let comment = self.textDict[.comment] ?? ""

            let params: [String: Any] = [
                "phone": phone,
                "primary": self.textDict[.primarySwitch] == "true",
                self.listType.typeKey: [
                    "id": type.id,
                    "name": type.name
                ],
                "comment": comment
            ]

            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.addOrEditPhone(with: params, mode: self.mode, contactId: self.personId, phoneId: self.id).promise
            }.done { [weak self] _ in
                guard let self = self else {
                    return
                }
                NotificationCenter.default.post(name: .personContactsChanged, object: nil)
                self.controller?.dismiss(animated: true) {
                    self.completion?(true)
                }
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) addOrEdit phone failed",
						parameters: error.asDictionary
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING PHONE:\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        case .email:
            let email = self.textDict[.email] ?? ""
            let comment = self.textDict[.comment] ?? ""

            let params: [String: Any] = [
                "email": email,
                "primary": self.textDict[.primarySwitch] == "true",
                self.listType.typeKey: [
                    "id": type.id,
                    "name": type.name
                ],
                "comment": comment
            ]

            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.addOrEditEmail(with: params, mode: self.mode, contactId: self.personId, emailId: self.id).promise
            }.done { [weak self] _ in
                guard let self = self else {
                    return
                }
                NotificationCenter.default.post(name: .personContactsChanged, object: nil)
                self.controller?.dismiss(animated: true) {
                    self.completion?(true)
                }
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) addOrEdit email failed",
						parameters: error.asDictionary
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING EMAIL:\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        default:
            return
        }
    }

    func delete() {
        self.controller?.showActivity()

        guard let id = self.id else {
            self.controller?.hideActivity()
            return
        }

        self.controller?.showDeleteAlert(type: self.listType) { [weak self] in
            guard let self = self else {
                return
            }
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.delete(with: id, contactId: self.personId, type: self.listType).promise
            }.done { [weak self] _ in
                guard let self = self else {
                    return
                }
                NotificationCenter.default.post(name: .personContactsChanged, object: nil)
                self.controller?.dismiss(animated: true) {
                    self.completion?(true)
                }
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) delete failed",
						parameters: error.asDictionary.appending("contactId", id)
					)
				
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE DELETING ITEM \(id):\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        }
    }

    // MARK: - Helpers

    private func setup() {
        if self.mode == .addition {
            let isPrimary: Bool? = (self.listType == .address) ? nil : false
            let viewModel = ContactAdditionViewModel(
                type: self.listType,
                mode: self.mode,
                isPrimary: isPrimary
            )
            self.controller?.setup(with: viewModel)
            return
        }

        guard let id = self.id else {
            return
        }

        switch self.listType {
        case .phone:
            self.setupPhone(for: id)
        case .email:
            self.setupEmail(for: id)
        case .address:
            self.setupAddress(for: id)
        }
    }

    private func setupPhone(for id: ContactID) {
        self.controller?.showActivity()

        DispatchQueue.global(qos: .userInitiated).promise {
            self.contactsEndpoint.getContactPhone(contactId: self.personId, phoneId: id).promise
        }.done { [weak self] phone in
            guard let self = self else {
                return
            }
            let contactType = ContactTypeViewModel(
                id: phone.phoneType?.id ?? -1,
                name: phone.phoneType?.name ?? ""
            )
            let phoneViewModel = ContactAdditionPhoneFieldViewModel(phoneNumber: phone.phone ?? "")
            let viewModel = ContactAdditionViewModel(
                type: self.listType,
                mode: self.mode,
                phoneViewModel: phoneViewModel,
                contactType: contactType,
                comment: phone.comment,
                isPrimary: phone.isPrimary
            )
            if let phone = phone.phone {
                self.textDict[.phone] = phone
            }
            if let comment = phone.comment {
                self.textDict[.comment] = comment
            }
            self.contactType = contactType
            self.controller?.setup(with: viewModel)
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) getContactPhone failed",
					parameters: error.asDictionary.appending("contactId", id)
				)

			AlertPresenter.alertCommonError(error)
            DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING PHONE(ID: \(id):\(error.localizedDescription)")
        }.finally { [weak self] in
            self?.controller?.hideActivity()
        }
    }

    private func setupEmail(for id: ContactID) {
        self.controller?.showActivity()

        DispatchQueue.global(qos: .userInitiated).promise {
            self.contactsEndpoint.getContactEmail(contactId: self.personId, emailId: id).promise
        }.done { [weak self] email in
            guard let self = self else {
                return
            }
            let contactType = ContactTypeViewModel(
                id: email.emailType?.id ?? -1,
                name: email.emailType?.name ?? ""
            )
            let viewModel = ContactAdditionViewModel(
                type: self.listType,
                mode: self.mode,
                contact: email.email,
                contactType: contactType,
                comment: email.comment,
                isPrimary: email.isPrimary
            )
            if let email = email.email {
                self.textDict[.email] = email
            }
            if let comment = email.comment {
                self.textDict[.comment] = comment
            }
            self.contactType = contactType
            self.controller?.setup(with: viewModel)
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) setupEmail failed",
					parameters: error.asDictionary.appending("contactId", id)
				)

			AlertPresenter.alertCommonError(error)
            DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING EMAIL(ID: \(id):\(error.localizedDescription)")
        }.finally { [weak self] in
            self?.controller?.hideActivity()
        }
    }

    private func setupAddress(for id: ContactID) {
    }

    private func getContactTypes() {
        self.controller?.showActivity()

        switch self.listType {
        case .phone:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getPhoneTypes().promise
            }.done { [weak self] types in
                guard let self = self else {
                    return
                }
                self.contactTypeData = types.data?.map {
                    ContactTypeViewModel(id: $0.id ?? -1, name: $0.name ?? "")
                } ?? []
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getPhoneTypes failed",
						parameters: error.asDictionary
					)

				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING PHONE TYPES:\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        case .email:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getEmailTypes().promise
            }.done { [weak self] types in
                guard let self = self else {
                    return
                }
                self.contactTypeData = types.data?.map {
                    ContactTypeViewModel(id: $0.id ?? -1, name: $0.name ?? "")
                } ?? []
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getEmailTypes failed",
						parameters: error.asDictionary
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING EMAIL TYPES:\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        default:
            return
        }
    }

    private func isValid(phoneNumber: String) -> Bool {
        let number = try? PhoneNumberKit().parse(phoneNumber)
        return number != nil
    }

    private func isValid(email: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: email)
    }
}
