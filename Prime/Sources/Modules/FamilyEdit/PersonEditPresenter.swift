import Foundation
import PromiseKit

extension Notification.Name {
    static let profilePersonsChanged = Notification.Name("Profile.Persons.Changed")
}

protocol PersonEditPresenterProtocol: AnyObject {
    func loadForm()
    func saveForm()
    func deleteForm()
}

final class PersonEditPresenter: PersonEditPresenterProtocol {
    weak var viewController: PersonEditViewControllerProtocol?
    
    private var contact: Contact
    private let familyService: FamilyServiceProtocol
    private var contactTypes: [ContactType]
    private var selectedType: ContactType

    init(
        contact: Contact,
        familyService: FamilyServiceProtocol,
        contactTypes: [ContactType]
    ) {
        self.contact = contact
        self.familyService = familyService
        self.contactTypes = contactTypes
        self.selectedType = .init(id: -1, name: contact.contactType?.name ?? "")
    }
    
    func loadForm() {
        var fields: [FamilyEditFormField] = []
        let indexType = contactTypes.firstIndex(where: { $0.id == self.contact.contactType?.id })
        fields = [
            .picker(
                FamilyEditPickerModel(
                    title: Localization.localize("persons.edit.type"),
                    values: contactTypes.compactMap(\.name),
                    selectedIndex: indexType,
                    pickerInvoker: { [weak self] in
                        self?.presentTypePicker()
                    }
                )
            ),
            .textField(
                FamilyEditTextFieldModel(
                        title: Localization.localize("persons.edit.first.name") + "*",
                        placeholder: Localization.localize("persons.edit.first.name"),
                        value: self.contact.firstName ?? "",
                        onUpdate: { [weak self] val in
                            self?.contact.firstName = val
                        }
                    )
            ),
            .textField(
                FamilyEditTextFieldModel(
                        title: Localization.localize("persons.edit.last.name") + "*",
                        placeholder: Localization.localize("persons.edit.last.name"),
                        value: self.contact.lastName ?? "",
                        onUpdate: { [weak self] val in
                            self?.contact.lastName = val
                        }
                    )
            ),
            .textField(
                FamilyEditTextFieldModel(
                        title: Localization.localize("persons.edit.middle.name"),
                        placeholder: Localization.localize("persons.edit.middle.name"),
                        value: self.contact.middleName ?? "",
                        onUpdate: { [weak self] val in
                            self?.contact.middleName = val
                        }
                    )
            ),
            .datePicker(
                FamilyEditDatePickerModel(
                    title: Localization.localize("persons.edit.birthday"),
                    placeholder: Localization.localize("persons.edit.birthday"),
					value: self.contact.birthDate?.date("yyyy-MM-dd")?.birthdayString ?? "",
                    onSelect: { [weak self] date in self?.contact.birthDate = date.customDateString }
                )
            )
        ]
        
        self.viewController?.update(with: fields)
    }
    
    func saveForm() {
        self.viewController?.showActivity()
        let contactValidationField = [
            self.contact.firstName,
            self.contact.lastName,
            self.contact.contactType?.name
        ]
        let isValidToSave = contactValidationField.allSatisfy { $0?.isEmpty == false }
        
        guard isValidToSave else {
            self.viewController?.show(error: Localization.localize("documents.form.validation.error"))
            return
        }
        
        
        DispatchQueue.global().promise { () -> Promise<Contact> in
            if self.contact.id != nil {
                return self.familyService.updateContact(contact: self.contact)
            } else {
                return self.familyService.createContact(contact: self.contact)
            }
        }
        .done { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            NotificationCenter.default.post(name: .profilePersonsChanged, object: nil)
            delay(0.5) {
                strongSelf.viewController?.closeFormWithSuccess()
            }
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) familyService.updateContact failed",
					parameters: error.asDictionary
				)

            self.viewController?.show(error: Localization.localize("documents.form.commonError"))
        }
    }
    
    func deleteForm() {
        guard let id = self.contact.id else {
            return
        }

        self.viewController?.showActivity()
        DispatchQueue.global().promise {
            self.familyService.removeContact(with: id)
        }
        .done { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            NotificationCenter.default.post(name: .profilePersonsChanged, object: nil)
            strongSelf.viewController?.hideActivity()
            strongSelf.viewController?.closeFormWithSuccess()
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) removeContact failed",
					parameters: error.asDictionary
				)
            self.viewController?.show(error: Localization.localize("documents.form.commonError"))
        }
    }

    private func presentTypePicker() {
        self.viewController?.presentPersonsTypePicker(
            selected: self.selectedType,
            onSelect: { [weak self] type in
                self?.selectedType = type
                self?.contact.contactType = type
                self?.generateUpdatedPricker()
            }
        )
    }
    
    private func generateUpdatedPricker() {
        let indexType = contactTypes.firstIndex(where: { $0.id == self.contact.contactType?.id })
        let model =  FamilyEditPickerModel(
            title: "persons.edit.type".localized,
            values: contactTypes.compactMap(\.name),
            selectedIndex: indexType,
            pickerInvoker: { [weak self] in
                self?.presentTypePicker()
            }
        )
        self.viewController?.update(with: model)
    }
}
