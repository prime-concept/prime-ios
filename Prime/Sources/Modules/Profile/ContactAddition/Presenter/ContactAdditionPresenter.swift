import Foundation
import PhoneNumberKit
import PromiseKit

extension Notification.Name {
	static let profileContactsChanged = Notification.Name("Profile.Contacts.Changed")
}

protocol ContactAdditionPresenterProtocol {
    func didLoad()
    func save(text: String, for key: ContactAdditionFieldType)
    func didTapOnCodeSelection()
    func didTapOnSelection(_ type: ContactAdditionFieldType)
    func addOrEdit()
    func delete()
}

final class ContactAdditionPresenter: ContactAdditionPresenterProtocol {
    private let listType: ContactsListType
    private let mode: ContactAdditionMode
    private let id: ContactID?
    private let contactsEndpoint: ContactsEndpointProtocol
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
        endpoint: ContactsEndpointProtocol,
        completion: @escaping ((Bool) -> Void)
    ) {
        self.listType = listType
        self.mode = mode
        self.id = id
        self.contactsEndpoint = endpoint
        self.completion = completion
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
                self.contactsEndpoint.addOrEditPhone(with: params, mode: self.mode, id: self.id).promise
            }.done { [weak self] _ in
                guard let self = self else {
                    return
                }
				NotificationCenter.default.post(name: .profileContactsChanged, object: nil)
                self.controller?.dismiss(animated: true) {
                    self.completion?(true)
                }
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) addOrEditPhone failed",
						parameters: error.asDictionary.appending("params", params).appending("mode", self.mode)
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING PHONE: \(error.localizedDescription)")
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
                self.contactsEndpoint.addOrEditEmail(with: params, mode: self.mode, id: self.id).promise
            }.done { [weak self] _ in
                guard let self = self else {
                    return
                }
                NotificationCenter.default.post(name: .profileContactsChanged, object: nil)
                self.controller?.dismiss(animated: true) {
                    self.completion?(true)
                }
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) addOrEditEmail failed",
						parameters: error.asDictionary
							.appending("params", params)
							.appending("mode", self.mode)
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING PHONE:\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        case .address:
            let street = self.textDict[.street] ?? ""
            let house = self.textDict[.house] ?? ""
            let flat = self.textDict[.apartment] ?? ""

            let comment = self.textDict[.comment] ?? ""

            let params: [String: Any] = [
                "country": [
                    "id": self.selectedCountry?.id ?? 0,
                    "name": self.selectedCountry?.name ?? ""
                ],
                "city": [
                    "id": self.selectedCity?.id ?? 0,
                    "name": self.selectedCity?.name ?? ""
                ],
                "cityId": self.selectedCity?.id ?? 0,
                "countryId": self.selectedCountry?.id ?? 0,
                "street": street,
                "house": house,
                "flat": flat,
                self.listType.typeKey: [
                    "id": type.id,
                    "name": type.name
                ],
                "comment": comment
            ]

            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.addOrEditAddress(with: params, mode: self.mode, id: self.id).promise
            }.done { [weak self] _ in
                guard let self = self else {
                    return
                }
                NotificationCenter.default.post(name: .profileContactsChanged, object: nil)
                self.controller?.dismiss(animated: true) {
                    self.completion?(true)
                }
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) addOrEditAddress failed",
						parameters: error.asDictionary.appending("params", params).appending("mode", self.mode)
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING ADDRESS:\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        }
    }

    func delete() {
        guard let id = self.id else {
            return
        }

        self.controller?.showDeleteAlert(type: self.listType) { [weak self] in
            guard let self = self else {
                return
            }
			self.controller?.showActivity()

            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.delete(with: id, type: self.listType).promise
            }.done { [weak self] _ in
                guard let self = self else {
                    return
                }
				NotificationCenter.default.post(name: .profileContactsChanged, object: nil)
                self.controller?.dismiss(animated: true) {
                    self.completion?(true)
                }
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) delete failed",
						parameters: error.asDictionary
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
			self.contactsEndpoint.getPhone(with: id).promise
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
					name: "[ERROR] \(Swift.type(of: self)) getPhone failed",
					parameters: error.asDictionary
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
			self.contactsEndpoint.getEmail(with: id).promise
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
					name: "[ERROR] \(Swift.type(of: self)) getEmail failed",
					parameters: error.asDictionary
				)
			AlertPresenter.alertCommonError(error)
			DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING EMAIL(ID: \(id):\(error.localizedDescription)")
		}.finally { [weak self] in
            self?.controller?.hideActivity()
        }
	}

	private func setupAddress(for id: ContactID) {
        self.controller?.showActivity()

		DispatchQueue.global(qos: .userInitiated).promise {
			self.contactsEndpoint.getAddress(with: id).promise
		}.done { [weak self] address in
			guard let self = self else {
				return
			}
			let contactType = ContactTypeViewModel(
				id: address.addressType?.id ?? -1,
				name: address.addressType?.name ?? ""
			)
			let addressViewModel = ContactAdditionAddressFieldViewModel(from: address)
			let viewModel = ContactAdditionViewModel(
				type: self.listType,
				mode: self.mode,
				addressViewModel: addressViewModel,
				contactType: contactType,
				comment: address.comment
			)
			self.selectedCity = address.city
			self.selectedCountry = address.country
			if let house = address.house {
				self.textDict[.house] = house
			}
			if let street = address.street {
				self.textDict[.street] = street
			}
			if let flat = address.flat {
				self.textDict[.apartment] = flat
			}
			if let comment = address.comment {
				self.textDict[.comment] = comment
			}
			self.contactType = contactType
			self.controller?.setup(with: viewModel)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) getAddress failed",
					parameters: error.asDictionary
				)
			AlertPresenter.alertCommonError(error)
			DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING ADDRESS(ID: \(id):\(error.localizedDescription)")
		}.finally { [weak self] in
            self?.controller?.hideActivity()
        }
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
        case .address:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getAddressTypes().promise
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
						name: "[ERROR] \(Swift.type(of: self)) getAddressTypes failed",
						parameters: error.asDictionary
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING EMAIL TYPES:\(error.localizedDescription)")
            }.finally { [weak self] in
                self?.controller?.hideActivity()
            }
        }
    }

    private func isValid(phoneNumber: String) -> Bool {
        let number = try? PhoneNumberKit().parse(phoneNumber, addPlusIfFails: true)
        return number != nil
    }

    private func isValid(email: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: email)
    }
}
