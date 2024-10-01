import Foundation
import PhoneNumberKit
import PromiseKit

protocol ContactsListPresenterProtocol {
    func didLoad()
    func didTapOnAddContact()
    func didTapOnContact(with id: Int)
}

final class ContactsListPresenter: ContactsListPresenterProtocol {
    weak var controller: ContactsListViewControllerProtocol?
    private let contactsEndpoint: ContactsEndpointProtocol
    private let listType: ContactsListType
    private lazy var phoneNumberKit = PhoneNumberKit()

    init(
        contactsEndpoint: ContactsEndpointProtocol,
        listType: ContactsListType
    ) {
        self.contactsEndpoint = contactsEndpoint
        self.listType = listType
    }

    func didLoad() {
        self.retrieveContacts(by: self.listType)
    }

    func didTapOnAddContact() {
        let assembly = ContactAdditionAssembly(mode: .addition, listType: self.listType) { [weak self] success in
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
        let assembly = ContactAdditionAssembly(mode: .edit, listType: self.listType, id: id) { [weak self] success in
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
		self.controller?.showLoadingIndicator()

        switch type {
        case .phone:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getPhones().promise
            }.done { [weak self] phones in
                guard let self = self else {
                    return
                }
                let viewModel = self.makeViewModel(with: phones)
                self.controller?.setup(with: viewModel)
			}.ensure { [weak self] in
				self?.controller?.hideLoadingIndicator()
			}.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getPhones failed",
						parameters: error.asDictionary
					)

				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING PHONES:\(error.localizedDescription)")
            }
        case .email:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getEmails().promise
            }.done { [weak self] emails in
                guard let self = self else {
                    return
                }
                let viewModel = self.makeViewModel(with: emails)
                self.controller?.setup(with: viewModel)
            }.ensure { [weak self] in
				self?.controller?.hideLoadingIndicator()
			}.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getEmails failed",
						parameters: error.asDictionary
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING EMAILS:\(error.localizedDescription)")
            }
        case .address:
            DispatchQueue.global(qos: .userInitiated).promise {
                self.contactsEndpoint.getAddresses().promise
            }.done { [weak self] addresses in
                guard let self = self else {
                    return
                }
                let viewModel = self.makeViewModel(with: addresses)
                self.controller?.setup(with: viewModel)
            }.ensure { [weak self] in
				self?.controller?.hideLoadingIndicator()
			}.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getAddress failed",
						parameters: error.asDictionary
					)
				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE GETTING ADDRESSES:\(error.localizedDescription)")
            }
        }
    }

    private func makeViewModel(with phones: Phones) -> ContactsListViewModel {
        let addButtonTitle = Localization.localize("profile.add.phone")
        var viewModel = ContactsListViewModel(
            addButtonTitle: addButtonTitle,
            cellViewModels: []
        )
        guard let phones = phones.data else {
            return viewModel
        }
        var sortedPhones: [Phone] = []
        let contactTypesSort = [2, 9, 268435466, 5, 3, 4, 8, 6, nil]
        contactTypesSort.forEach { type in
            sortedPhones.append(contentsOf: phones.filter {$0.phoneType?.id == type})
        }
        
        var cellViewModels = sortedPhones.compactMap { phone -> ContactsListTableViewCellViewModel? in
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
        
        if cellViewModels.isEmpty == false {
            cellViewModels[cellViewModels.endIndex - 1].separatorIsHidden = true
            viewModel.cellViewModels = cellViewModels
        }
        
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
