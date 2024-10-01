import UIKit

enum AlertContollerFactory {
    static func makeAlert(with message: String, actionHandler: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: Localization.localize("Ok"), style: .default) { _ in
            actionHandler?()
        }
        
        alert.addAction(okAction)
        return alert
    }

	static func makeDestructionAlert(
		with message: String,
		destructTitle: String,
		destruct:  @escaping () -> Void,
		cancelTitle: String = Localization.localize("common.cancel"),
		cancel: (() -> Void)? = nil
	) -> UIAlertController {
		let alert = UIAlertController(
			title: nil,
			message: message,
			preferredStyle: .alert
		)
		let descructAction = UIAlertAction(title: destructTitle, style: .destructive, handler: { _ in
			destruct()
		})
		alert.addAction(descructAction)
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in
			cancel?()
		})
		alert.addAction(cancelAction)
		return alert
	}

    static func makeBiometricErrorAlert(
        okAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: Localization.localize("permission.biometric.error.title"),
            message: Localization.localize("permission.biometric.error.description"),
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: Localization.localize("settings"), style: .default) { _ in
            okAction()
        }
        alert.addAction(okAction)
        let cancel = UIAlertAction(title: Localization.localize("permission.error.cancel"), style: .cancel) { _ in
            cancelAction()
        }
        alert.addAction(cancel)
        return alert
    }

    static func makeProfileContactDeletionAlert(
        type: ContactsListType,
        deleteAction: @escaping () -> Void
    ) -> UIAlertController {
        let title = Localization.localize("profile.delete.alert.\(type)")

        let alert = UIAlertController(
            title: title,
            message: "",
            preferredStyle: .alert
        )

        let cancel = UIAlertAction(title: Localization.localize("detailRequestCreation.cancel"), style: .cancel)
        alert.addAction(cancel)
        let deleteAction = UIAlertAction(title: Localization.localize("profile.delete"), style: .destructive) { _ in
            deleteAction()
        }
        alert.addAction(deleteAction)
        return alert
    }

    static func makeCameraErrorController(
        type: CameraErrorType,
        okAction: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: Localization.localize("permission.error.title"),
            message: type.description,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: Localization.localize("settings"), style: .default) { _ in
            okAction()
        }
        alert.addAction(okAction)
        let cancel = UIAlertAction(title: Localization.localize("permission.error.cancel"), style: .cancel)
        alert.addAction(cancel)
        return alert
    }
}
