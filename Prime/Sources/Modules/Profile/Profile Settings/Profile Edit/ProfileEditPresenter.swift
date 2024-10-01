import Foundation
import PromiseKit

typealias ProfileChange = (Profile) -> Void

protocol ProfileEditPresenterProtocol: AnyObject {
    func didLoad()
    func saveForm()
}

final class ProfileEditPresenter: ProfileEditPresenterProtocol {
    weak var controller: ProfileEditViewControllerProtocol?

    private let profileEndpoint: ProfileEndpointProtocol
    private let onProfileChange: ProfileChange
    private var profile: Profile

    init(
        profileEndpoint: ProfileEndpointProtocol,
        profile: Profile,
        onProfileChange: @escaping ProfileChange
    ) {
        self.profileEndpoint = profileEndpoint
        self.profile = profile
        self.onProfileChange = onProfileChange
    }

    func didLoad() {
        self.controller?.showActivity()
        self.loadForm()
        self.controller?.hideActivity()
    }

    func saveForm() {
        self.controller?.showActivity()

        let validationFields = [
            self.profile.firstName,
            self.profile.lastName
        ]
        let isValidToSave = validationFields.allSatisfy { $0?.isEmpty == false }

        guard isValidToSave else {
            self.controller?.show(error: Localization.localize("profile.validation.alert.message"))
            return
        }

        DispatchQueue.global(qos: .userInitiated).promise {
            self.profileEndpoint.update(with: self.profile).promise
        }.done { [weak self] _ in
            guard let self = self else {
                return
            }

            self.onProfileChange(self.profile)
            self.controller?.closeFormWithSuccess()
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) edit failed",
					parameters: error.asDictionary
				)

            self.showCommonError()
        }.finally { [weak self] in
            self?.controller?.hideActivity()
        }
    }

    // MARK: - Private

    private func loadForm() {
        var fields: [ProfileEditFormField] = []

        fields = [
            .textField(
                ProfileEditTextFieldModel(
                    title: Localization.localize("profile.edit.form.firstName"),
                    placeholder: Localization.localize("profile.edit.form.firstName"),
                    value: self.profile.firstName ?? "",
                    fieldType: .givenName,
                    onUpdate: { [weak self] val in self?.profile.firstName = val }
                )
            ),
            .emptySpace(10),

            .textField(
                ProfileEditTextFieldModel(
                    title: Localization.localize("profile.edit.form.lastName"),
                    placeholder: Localization.localize("profile.edit.form.lastName"),
                    value: self.profile.lastName ?? "",
                    fieldType: .familyName,
                    onUpdate: { [weak self] val in self?.profile.lastName = val }
                )
            ),
            .emptySpace(10),

            .textField(
                ProfileEditTextFieldModel(
                    title: Localization.localize("profile.edit.form.middleName"),
                    placeholder: Localization.localize("profile.edit.form.middleName"),
                    value: self.profile.middleName ?? "",
                    fieldType: .middleName,
                    onUpdate: { [weak self] val in self?.profile.middleName = val }
                )
            ),
            .emptySpace(10),

            .datePicker(
                ProfileEditDatePickerModel(
                    title: Localization.localize("profile.edit.form.birthday"),
                    placeholder: Localization.localize("profile.edit.form.birthday"),
					value: self.profile.birthday?.date("yyyy-MM-dd")?.birthdayString ?? "",
                    onSelect: { [weak self] date in self?.profile.birthday = date.customDateString }
                )
            )
        ]

        self.controller?.update(with: fields)
    }

    private func showCommonError() {
        self.controller?.show(error: Localization.localize("common.error"))
    }
}
