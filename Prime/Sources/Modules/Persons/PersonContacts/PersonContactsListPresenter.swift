import Foundation
import PhoneNumberKit
import PromiseKit

final class PersonContactsListPresenter: ContactsListPresenterProtocol {
    weak var controller: ContactsListViewControllerProtocol?
    private let contactsEndpoint: FamilyContactsEndpointProtocol
    private let listType: ContactsListType
    private let personId: Int
    private lazy var phoneNumberKit = PhoneNumberKit()

    init(
        contactsEndpoint: FamilyContactsEndpointProtocol,
        listType: ContactsListType,
        personId: Int
    ) {
        self.personId = personId
        self.contactsEndpoint = contactsEndpoint
        self.listType = listType
    }

    func didLoad() {
		var viewModel: ContactsListViewModel
		switch self.listType {
			case .address:
				viewModel = self.makeViewModel(with: Addresses(data: []))
			case .phone:
				viewModel = self.makeViewModel(with: Phones(data: []))
			case .email:
				viewModel = self.makeViewModel(with: Emails(data: []))
		}
		self.controller?.setup(with: viewModel)

        self.retrieveContacts(by: self.listType)
    }

    func didTapOnAddContact() {
        let assembly = PersonContactEditAssembly(
            mode: .addition,
            listType: self.listType,
            personId: self.personId
        ) { [weak self] success in
            guard let self = self else {
                return
            }
            if success {
                self.retrieveContacts(by: self.listType)
            }
        }
        let router = ModalRouter(
            source: self.controller,
            destination: assembly.make(),
            modalPresentationStyle: .pageSheet
        )
        router.route()
    }

    func didTapOnContact(with id: Int) {
        let assembly = PersonContactEditAssembly(
            mode: .edit,
            listType: self.listType,
            id: id,
            personId: self.personId
        ) { [weak self] success in
            guard let self = self else {
                return
            }
            if success {
                self.retrieveContacts(by: self.listType)
            }
        }
        let router = ModalRouter(
            source: self.controller,
            destination: assembly.make(),
            modalPresentationStyle: .pageSheet
        )
        router.route()
    }

    // MARK: - Helpers

    private func retrieveContacts(by type: ContactsListType) {
        switch type {
        case .phone:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getContactPhones(contactId: self.personId).promise
            }.done { [weak self] phones in
                guard let self = self else {
                    return
                }
                let viewModel = self.makeViewModel(with: phones)
                self.controller?.setup(with: viewModel)
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) retrieveContacts failed",
						parameters: error.asDictionary.appending("type", type)
					)

				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING PHONES:\(error.localizedDescription)")
            }
        case .email:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getContactEmails(contactId: self.personId).promise
            }.done { [weak self] emails in
                guard let self = self else {
                    return
                }
                let viewModel = self.makeViewModel(with: emails)
                self.controller?.setup(with: viewModel)
            }.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getContactEmails failed",
						parameters: error.asDictionary.appending("personId", self.personId)
					)

				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING EMAILS:\(error.localizedDescription)")
            }
        default:
            return
        }
    }

    private func makeViewModel(with phones: Phones) -> ContactsListViewModel {
        let addButtonTitle = Localization.localize("profile.add.phone")
        let cellViewModels = phones.data?.compactMap { phone -> ContactsListTableViewCellViewModel? in
            guard let number = phone.phone,
                  let parsedNumber = try? phoneNumberKit.parse(number, addPlusIfFails: true) else {
                return nil
            }
            let formattedNumber = self.phoneNumberKit.format(parsedNumber, toType: .international)
            let badgeText = (phone.isPrimary ?? false) ? "profile.contacts.primary".localized : nil
            return ContactsListTableViewCellViewModel(
                id: phone.id ?? -1,
                title: phone.phoneType?.name?.capitalizingFirstLetter() ?? "",
                subTitle: formattedNumber,
                badgeText: badgeText
            )
        }

        if var cellViewModels = cellViewModels, cellViewModels.isEmpty == false {
            cellViewModels[cellViewModels.endIndex - 1].separatorIsHidden = true
        }

        let viewModel = ContactsListViewModel(
            addButtonTitle: addButtonTitle,
            cellViewModels: cellViewModels ?? []
        )
        return viewModel
    }

    private func makeViewModel(with emails: Emails) -> ContactsListViewModel {
        let addButtonTitle = Localization.localize("profile.add.email")
        let cellViewModels = emails.data?.map { email -> ContactsListTableViewCellViewModel in
            let badgeText = (email.isPrimary ?? false) ? "profile.contacts.primary".localized : nil
            return ContactsListTableViewCellViewModel(
                id: email.id ?? -1,
                title: email.emailType?.name?.capitalizingFirstLetter() ?? "",
                subTitle: email.email ?? "",
                badgeText: badgeText
            )
        }

        if var cellViewModels = cellViewModels, cellViewModels.isEmpty == false {
            cellViewModels[cellViewModels.endIndex - 1].separatorIsHidden = true
        }

        let viewModel = ContactsListViewModel(
            addButtonTitle: addButtonTitle,
            cellViewModels: cellViewModels ?? []
        )
        return viewModel
    }

    private func makeViewModel(with addresses: Addresses) -> ContactsListViewModel {
        let addButtonTitle = Localization.localize("profile.add.address")
        let cellViewModels = addresses.data?.map { address -> ContactsListTableViewCellViewModel in
            ContactsListTableViewCellViewModel(
                id: address.id ?? -1,
                title: address.addressType?.name?.capitalizingFirstLetter() ?? "",
                subTitle: ContactAdditionAddressFieldViewModel(from: address).fullAddress
            )
        }

        if var cellViewModels = cellViewModels, cellViewModels.isEmpty == false {
            cellViewModels[cellViewModels.endIndex - 1].separatorIsHidden = true
        }

        let viewModel = ContactsListViewModel(
            addButtonTitle: addButtonTitle,
            cellViewModels: cellViewModels ?? []
        )
        return viewModel
    }
}
