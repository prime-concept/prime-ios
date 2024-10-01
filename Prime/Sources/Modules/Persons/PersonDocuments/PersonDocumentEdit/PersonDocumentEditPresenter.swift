import Foundation
import PromiseKit

extension Notification.Name {
    static let personDocumentsChanged = Notification.Name("Person.Document.Changed")
}

final class PersonDocumentEditPresenter: DocumentEditPresenterProtocol {
    weak var viewController: DocumentEditViewControllerProtocol?

    private var document: Document
    private let allDocuments: [Document]
    private let documentsService: FamilyDocumentsServiceProtocol
    private let filesService: FilesServiceProtocol
    private let permissionService: PermissionServiceProtocol
    private let formType: DocumentEditAssembly.FormType
    private var newVisaRelatedPassportID: Int?
    private var attachments: [DocumentEditAttachmentModel] = []
    private var selectedCountry: Country
    private let personId: Int

    init(
        view: DocumentEditViewControllerProtocol,
        document: Document,
        allDocuments: [Document],
        documentsService: FamilyDocumentsServiceProtocol,
        filesService: FilesServiceProtocol,
        permissionService: PermissionServiceProtocol,
        formType: DocumentEditAssembly.FormType,
        personId: Int
    ) {
        self.viewController = view
        self.document = document
        self.allDocuments = allDocuments
        self.documentsService = documentsService
        self.filesService = filesService
        self.permissionService = permissionService
        self.formType = formType
        self.personId = personId
        self.selectedCountry = .init(
            id: -1,
            name: document.countryName ?? "",
            code: document.countryCode,
            cities: nil
        )
    }

    func didLoad() {
        guard case .existing = self.formType else {
            self.loadForm()
            return
        }

        guard let documentId = self.document.id else {
            self.loadForm()
            return
        }

        self.viewController?.showActivity()
        self.filesService
            .list(forDocument: documentId)
            .done(on: .main) { [weak self] filesResponse in
                guard let self = self else {
                    return
                }
                guard let files = filesResponse.data else {
                    self.viewController?.hideActivity()
                    self.showCommonError()
                    self.loadForm()
                    return
                }
                let imagePromises = files.map { file in
                    DispatchQueue.global().promise {
                        self.filesService
                            .thumbnail(uuid: file.uid)
                            .compactMap(on: .main) { [weak self] (image) -> DocumentEditAttachmentModel? in
                                guard let self = self, let image = image else {
                                    return nil
                                }
                                return self.makeAttachment(with: file.uid, image: image)
                            }
                    }
                }

                when(fulfilled: imagePromises)
                    .done { [weak self] attachments in
                        self?.attachments = attachments
                    }
                    .ensure { [weak self] in
                        self?.viewController?.hideActivity()
                        self?.loadForm()
                    }
                    .catch { error in
						AnalyticsReportingService
							.shared.log(
								name: "[ERROR] \(Swift.type(of: self)) document attachments fetch failed",
								parameters: error.asDictionary.appending("documentId", documentId)
							)
                        self.showCommonError()
                    }
            }
            .ensure { [weak self] in
                self?.viewController?.hideActivity()
            }
            .catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) document attachments fetch failed",
						parameters: error.asDictionary.appending("documentId", documentId)
					)
                self.showCommonError()
            }
    }

    private func loadForm() {
        self.isVisa ? self.loadVisaForm() : self.loadPassportForm()
    }

    private var isVisa: Bool {
        switch self.document.documentType {
        case .passport, .other, .none:
            return false
        case .visa:
            return true
        }
    }

    func saveForm() {
        self.viewController?.showActivity()

        let passportValidationFields = [
            self.document.documentNumber,
            self.document.authority,
            self.document.citizenship,
            self.document.countryName
        ]

        var newVisaPassportNumber: String?
        if let newVisaPassportID = self.newVisaRelatedPassportID {
            newVisaPassportNumber = String(newVisaPassportID)
        }
        let visaPassportNumber = self.document.relatedPassport?.documentNumber ?? newVisaPassportNumber
        let visaValidationFields = [
            self.document.documentNumber,
            self.document.visaTypeId?.title,
            self.document.countryName,
            visaPassportNumber
        ]

        let isPassport = self.document.documentType == .passport
        let fields = isPassport ? passportValidationFields : visaValidationFields

        let isValidToSave = fields.allSatisfy { $0?.isEmpty == false }

        guard isValidToSave else {
            self.viewController?.show(error: Localization.localize("documents.form.validation.error"))
            return
        }

        let shouldAttachVisaToPassport = self.document.documentType == .visa
            && self.newVisaRelatedPassportID != nil
            && self.document.relatedPassport?.id != self.newVisaRelatedPassportID

        let queue = DispatchQueue.global()
        queue.promise { () -> Promise<Document> in
            if self.document.id != nil {
                return self.documentsService.update(contactId: self.personId, document: self.document)
            }

            return self.documentsService.create(contactId: self.personId, document: self.document)
        }
        .then(on: queue) { createdVisa -> Promise<Void> in
            self.document = createdVisa

            if shouldAttachVisaToPassport, let passportID = self.newVisaRelatedPassportID {
                return self.documentsService.attach(contactId: self.personId, visa: createdVisa, toPassportWithID: passportID)
            }

            return .value(())
        }
        .then(on: queue) { [weak self] () -> Promise<Void> in
            Promise<Void>() { seal in
                guard let self = self else {
                    seal.fulfill(())
                    return
                }
                when(fulfilled: self.attachmentPromises)
                    .done { seal.fulfill(()) }
                    .catch {
						AnalyticsReportingService
							.shared.log(
								name: "[ERROR] \(Swift.type(of: self)) document attachments save failed",
								parameters: $0.asDictionary
							)
						seal.reject($0)
					}
            }
        }
        .done { [weak self] _ in
            NotificationCenter.default.post(name: .personDocumentsChanged, object: nil)
            delay(0.5) {
                self?.viewController?.closeFormWithSuccess()
            }
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) document attachments list fetch failed",
					parameters: error.asDictionary
				)
            self.showCommonError()
        }
    }

    private var attachmentPromises: [Promise<Void>] {
        let promises: [Promise<Void>] = self.attachments.compactMap { attachment in
            if let uuid = attachment.uuid {
                if attachment.isDeleted {
                    return self.filesService.remove(uuid: uuid)
                }
                return nil
            }

            guard let id = self.document.id,
                  !attachment.isDeleted,
                  let data = attachment.original.jpegData(compressionQuality: 0.9) else {
                return nil
            }
            return self.filesService.upload(forDocument: id, data: data).asVoid()
        }

        return promises
    }

    func deleteForm() {
        guard let id = self.document.id else {
            return
        }

        self.viewController?.showActivity()

        DispatchQueue.main.promise {
            self.documentsService.delete(with: id, contactId: self.personId)
        }
        .done { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            NotificationCenter.default.post(name: .personDocumentsChanged, object: nil)
            delay(0.5) {
                strongSelf.viewController?.closeFormWithSuccess()
            }
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) document delete failed",
					parameters: error.asDictionary
				)

            self.showCommonError()
        }
    }

    func didTapOnAttachmentsAddition() {
        self.permissionService.requestCamera(type: .photo) { [weak self] in
            self?.viewController?.showImagePickerController { result, error  in
                guard let self = self else {
                    return
                }
                defer {
                    self.loadForm()
                }

                guard error == nil else {
                    self.showCommonError()
                    return
                }

                let models = result.map { image in
                    self.makeAttachment(image: image)
                }
                self.update(attachments: models)
            }
        }
    }

    func update(attachments: [DocumentEditAttachmentModel]) {
        self.attachments.insert(contentsOf: attachments, at: 0)
    }

    // MARK: - Private

    private func loadPassportForm() {
        var fields: [DocumentEditFormField] = []

        fields = [
            .emptySpace(2),
            .attachments(self.attachments.filter { !$0.isDeleted }),
            .emptySpace(5),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.firstName"),
                    placeholder: Localization.localize("documents.form.firstName"),
                    value: self.document.firstName ?? "",
                    fieldType: .givenName,
                    onUpdate: { [weak self] val in self?.document.firstName = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.lastName"),
                    placeholder: Localization.localize("documents.form.lastName"),
                    value: self.document.lastName ?? "",
                    fieldType: .familyName,
                    onUpdate: { [weak self] val in self?.document.lastName = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.middleName"),
                    placeholder: Localization.localize("documents.form.middleName"),
                    value: self.document.middleName ?? "",
                    fieldType: .middleName,
                    onUpdate: { [weak self] val in self?.document.middleName = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.birthPlace"),
                    placeholder: Localization.localize("documents.form.birthPlace"),
                    value: self.document.birthPlace ?? "",
                    fieldType: .text,
                    onUpdate: { [weak self] val in self?.document.birthPlace = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.nationality") + " *",
                    placeholder: Localization.localize("documents.form.nationality"),
                    value: self.document.citizenship ?? "",
                    fieldType: .text,
                    onUpdate: { [weak self] val in self?.document.citizenship = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.documentNumber") + " *",
                    placeholder: Localization.localize("documents.form.documentNumber"),
                    value: self.document.documentNumber ?? "",
                    fieldType: .text,
                    onUpdate: { [weak self] val in self?.document.documentNumber = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.issuingAuthority")  + " *",
                    placeholder: Localization.localize("documents.form.issuingAuthority"),
                    value: self.document.authority ?? "",
                    fieldType: .text,
                    onUpdate: { [weak self] val in self?.document.authority = val }
                )
            ),
            .emptySpace(20),

            .countryPicker(
                DocumentEditCountryPickerModel(
                    title: Localization.localize("documents.form.issuingCountry") + " *",
                    placeholder: Localization.localize("documents.form.issuingCountry"),
                    value: self.document.countryName ?? "",
                    pickerInvoker: { [weak self] in
                        self?.presentCountryPicker()
                    }
                )
            ),
            .emptySpace(20),

            .datePicker(
                DocumentEditDatePickerModel(
                    title: Localization.localize("documents.form.dateOfIssue"),
                    placeholder: Localization.localize("documents.form.dateOfIssue"),
                    value: self.document.issueDate ?? "",
                    onSelect: { [weak self] date in self?.document.issueDate = date.customDateString }
                )
            ),
            .emptySpace(20),

            .datePicker(
                DocumentEditDatePickerModel(
                    title: Localization.localize("documents.form.dateOfExpiry"),
                    placeholder: Localization.localize("documents.form.dateOfExpiry"),
                    value: self.document.expiryDate ?? "",
                    onSelect: { [weak self] date in self?.document.expiryDate = date.customDateString }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.authorityId"),
                    placeholder: Localization.localize("documents.form.authorityId"),
                    value: self.document.authorityId ?? "",
                    fieldType: .text,
                    onUpdate: { [weak self] val in self?.document.authorityId = val }
                )
            ),
            .emptySpace(24)
        ]

        self.viewController?.update(with: fields)
    }

    private func loadVisaForm() {
        var fields: [DocumentEditFormField] = []

        let availablePassports = self.allDocuments
            .filter { $0.documentType == .passport && $0.documentNumber != nil && $0.id != nil }

        var relatedPassportId = self.isVisa ? self.newVisaRelatedPassportID : self.document.relatedPassport?.id
        relatedPassportId ??= self.document.relatedPassport?.id

        let selectedPassportIndex = availablePassports.firstIndex(where: { $0.id == relatedPassportId })

        let availableVisaTypes = VisaType.allCases
        let selectedVisaIndex = availableVisaTypes.firstIndex(where: { $0 == self.document.visaTypeId })

        fields = [
            .picker(
                DocumentEditPickerModel(
                    title: Localization.localize("documents.form.visaType") + " *",
                    values: availableVisaTypes.map(\.title),
                    selectedIndex: selectedVisaIndex,
                    onSelect: { [weak self] idx in
                        self?.document.visaTypeId = availableVisaTypes[idx]
                    }
                )
            ),
            .emptySpace(10)
        ]

        if !availablePassports.isEmpty {
            fields += [
                .picker(
                    DocumentEditPickerModel(
                        title: Localization.localize("documents.form.passport") + " *",
                        values: availablePassports.compactMap(\.documentNumber),
                        selectedIndex: selectedPassportIndex,
                        onSelect: { [weak self] idx in
                            self?.newVisaRelatedPassportID = availablePassports[idx].id
                        }
                    )
                ),
                .emptySpace(10)
            ]
        }

        fields += [
            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.firstName"),
                    placeholder: Localization.localize("documents.form.firstName"),
                    value: self.document.firstName ?? "",
                    fieldType: .givenName,
                    onUpdate: { [weak self] val in self?.document.firstName = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.lastName"),
                    placeholder: Localization.localize("documents.form.lastName"),
                    value: self.document.lastName ?? "",
                    fieldType: .familyName,
                    onUpdate: { [weak self] val in self?.document.lastName = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.middleName"),
                    placeholder: Localization.localize("documents.form.middleName"),
                    value: self.document.middleName ?? "",
                    fieldType: .middleName,
                    onUpdate: { [weak self] val in self?.document.middleName = val }
                )
            ),
            .emptySpace(20),

            .textField(
                DocumentEditTextFieldModel(
                    title: Localization.localize("documents.form.visaNumber") + " *",
                    placeholder: Localization.localize("documents.form.visaNumber"),
                    value: self.document.documentNumber ?? "",
                    fieldType: .number,
                    onUpdate: { [weak self] val in self?.document.documentNumber = val }
                )
            ),
            .emptySpace(20),

            .countryPicker(
                DocumentEditCountryPickerModel(
                    title: Localization.localize("documents.form.issuingCountry") + " *",
                    placeholder: Localization.localize("documents.form.issuingCountry"),
                    value: self.document.countryName ?? "",
                    pickerInvoker: { [weak self] in
                        self?.presentCountryPicker()
                    }
                )
            ),

            .emptySpace(20),

            .datePicker(
                DocumentEditDatePickerModel(
                    title: Localization.localize("documents.form.dateOfIssue"),
                    placeholder: Localization.localize("documents.form.dateOfIssue"),
                    value: self.document.issueDate ?? "",
                    onSelect: { [weak self] date in self?.document.issueDate = date.customDateString }
                )
            ),
            .emptySpace(20),

            .datePicker(
                DocumentEditDatePickerModel(
                    title: Localization.localize("documents.form.dateOfExpiry"),
                    placeholder: Localization.localize("documents.form.dateOfExpiry"),
                    value: self.document.expiryDate ?? "",
                    onSelect: { [weak self] date in self?.document.expiryDate = date.customDateString }
                )
            ),
            .emptySpace(24)
        ]

        self.viewController?.update(with: fields)
    }

    private func presentCountryPicker() {
        self.viewController?.presentCountryPicker(
            selected: self.selectedCountry,
            onSelect: { [weak self] country in
                self?.selectedCountry = country
                self?.document.countryName = country.name
                self?.document.countryCode = country.code

                self?.loadForm()
            }
        )
    }

    private func makeAttachment(with uuid: String? = nil, image: UIImage) -> DocumentEditAttachmentModel {
        DocumentEditAttachmentModel(
            uuid: uuid,
            original: image,
            thumbnail: nil
        ) {
            self.removeAttachment(with: image)
            self.loadForm()
        } onSelect: {
			self.showImageViewer(with: uuid, image: image)
		}
    }

	private func showImageViewer(with uuid: String? = nil, image: UIImage) {
		let imageViewer = FullImageViewController.fullscreen(with: image)
		imageViewer.show {
			guard let uuid = uuid else {
				return
			}

			imageViewer.showLoadingIndicator(isUserInteractionEnabled: true, needsPad: true)

			self.filesService
                .image(byUUID: uuid)
				.done(on: .main) { [weak imageViewer] image in
                    imageViewer?.set(image: image)
                    imageViewer?.hideLoadingIndicator()
				}
				.catch { error in
                    AnalyticsReportingService.shared.log(
                        error: error.localizedDescription,
                        parameters: error.asDictionary.appending("uuid", uuid)
                    )
				}
		}
	}

    private func removeAttachment(with image: UIImage) {
        self.attachments = self.attachments.compactMap { attachment in
            guard attachment.original == image else {
                return attachment
            }

            if attachment.uuid == nil {
                return nil
            }

            return .init(
                uuid: attachment.uuid,
                original: attachment.original,
                thumbnail: attachment.thumbnail,
                isDeleted: true,
				onDelete: attachment.onDelete,
				onSelect: attachment.onSelect
            )
        }
    }

    private func showCommonError() {
        self.viewController?.show(error: Localization.localize("documents.form.commonError"))
    }
}
