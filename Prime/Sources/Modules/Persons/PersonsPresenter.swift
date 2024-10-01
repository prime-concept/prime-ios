import Foundation
import PromiseKit
import UIKit

protocol PersonsPresenterProtocol: AnyObject {
    func loadFamilyMembers()
    func openForm(contactIndex: Int)
    func presentForm(for type: PersonEditAssembly.PersonFormType)
}

final class PersonsPresenter: PersonsPresenterProtocol {
    weak var viewController: PersonsViewControllerProtocol?
    private let familyService: FamilyServiceProtocol
    
    private var familyMembers: [Contact]?

    init(familyService: FamilyServiceProtocol) {
        self.familyService = familyService
        
        self.familyService.subscribeForUpdates(receiver: self) { [weak self] updatedMembers in
            self?.updateFamilyMembers(updatedMembers)
        }
        self.loadContactTypes()
        self.listenToPersonsDataChanged()
    }

    deinit {
        self.familyService.unsubscribeFromUpdates(receiver: self)
    }
    
    private func listenToPersonsDataChanged() {
        let notifications: [Notification.Name] = [
            .personContactsChanged,
            .personDocumentsChanged
        ]

        notifications.forEach { name in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(personDataChanged),
                name: name,
                object: nil
            )
        }
    }
    
    @objc
    private func personDataChanged(_ notification: Notification) {
        self.loadFamilyMembers()
    }

    func loadFamilyMembers() {
        self.viewController?.showActivity()
        
        DispatchQueue.global().promise {
            self.familyService.getContacts()
        }
        .done { [weak self] contacts in
            self?.updateFamilyMembers(contacts)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) updateFamilyMembers failed",
					parameters: error.asDictionary
				)
		}
    }

    private func updateFamilyMembers(_ familyMembers: [Contact]) {
        let viewModel = familyMembers.map{
            PersonsViewModels(
                personInfo: PersonInfoViewModel.makeFamilyMemberModel(from: $0),
                docs: self.handle(docs: $0.documents ?? []),
                contacts: self.handle(phones: $0.phones ?? [], emails: $0.emails ?? [])
            )
        }
        self.familyMembers = familyMembers
        self.viewController?.update(with: viewModel)
    }

	func loadContactTypes() {
		DispatchQueue.global()
			.promise {
				self.familyService.getContactTypes()
			}.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) loadContactTypes failed",
						parameters: error.asDictionary
					)
			}
	}

    func openForm(contactIndex: Int) {
        guard let contact = self.familyMembers?[safe: contactIndex] else {
            return
        }

        self.presentForm(for: .existing(contact))
    }
    
    func presentForm(for type: PersonEditAssembly.PersonFormType) {
        let assembly = PersonEditAssembly(type: type)
        let controller = assembly.make()
        self.viewController?.presentForm(controller: controller)
    }

    private func handle(docs: [Document]) -> ProfilePersonalInfoCellViewModel {
        let passports = docs.filter { $0.documentType == .passport }
        let visas = docs.filter { $0.documentType == .visa }

        let count = passports.count + visas.count
        let items: [ProfilePersonalInfoCellViewModel.Item]
        // swiftlint:disable:next empty_count
        if count == 0 {
            let empty = self.makeEmptyContentItem(
                with: "profile.addDocuments".localized,
                subtitle: "profile.emptyDescription".localized
            )
            items = [empty]
        } else {
            items = [
                .init(
                    title: "profile.passports".localized,
                    count: "\(passports.count)",
                    content: .plain(UIImage(named: "profile_visa&passport_icon"))
                ),
                .init(
                    title: "profile.visas".localized,
                    count: "\(visas.count)",
                    content: .plain(UIImage(named: "profile_visa&passport_icon"))
                )
            ].filter { $0.count != "0" }
        }

        let viewModel = ProfilePersonalInfoCellViewModel(
            title: "profile.documents".localized,
            count: "\(count)",
            items: items,
            supportedItemNames: [
                "profile.passports".localized,
                "profile.visas".localized
            ],
            onCountTap: { [weak self] in
                self?.viewController?.presentDocuments(index: 0, shouldOpenInCreationMode: false)
            },
            openDetailsOnTabWithIndex: { [weak self] inx, flag in
                self?.viewController?.presentDocuments(index: inx, shouldOpenInCreationMode: flag)
            }
        )

        return viewModel
    }

    private func handle(phones: [Phone], emails: [Email]) -> ProfilePersonalInfoCellViewModel {
        let count = phones.count + emails.count
        let items: [ProfilePersonalInfoCellViewModel.Item]
        // swiftlint:disable:next empty_count
        if count == 0 {
            let empty = self.makeEmptyContentItem(
                with: "profile.addContacts".localized,
                subtitle: "profile.emptyDescription".localized
            )
            items = [empty]
        } else {
            items = [
                .init(
                    title: "profile.phones".localized,
                    count: "\(phones.count)",
                    content: .plain(UIImage(named: "profile_phone_icon"))
                ),
                .init(
                    title: "profile.emails".localized,
                    count: "\(emails.count)",
                    content: .plain(UIImage(named: "profile_mail_icon"))
                )
            ].filter { $0.count != "0" }
        }

        let viewModel = ProfilePersonalInfoCellViewModel(
            title: Localization.localize("profile.contacts"),
            count: "\(count)",
            items: items,
            supportedItemNames: [
                "profile.phones".localized,
                "profile.emails".localized
            ],
            onCountTap: { [weak self] in
                self?.viewController?.presentContacts(index: 0, shouldOpenInCreationMode: false)
            },
            openDetailsOnTabWithIndex: { [weak self] inx, flag in
                self?.viewController?.presentContacts(index: inx, shouldOpenInCreationMode: flag)
            }
        )

        return viewModel
    }

    private func makeEmptyContentItem(with title: String, subtitle: String) -> ProfilePersonalInfoCellViewModel.Item {
        ProfilePersonalInfoCellViewModel.Item(
            title: "",
            count: "0",
            content: .empty(title, subtitle)
        )
    }
}
