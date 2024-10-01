import Foundation
import UIKit

protocol OtherSettingsPresenterProtocol: AnyObject {
    func numberOfRows(in section: Int) -> Int
    func setting(at indexPath: IndexPath) -> OtherSettingViewModel
    func saveForm()
}

final class OtherSettingsPresenter: OtherSettingsPresenterProtocol {
    weak var controller: OtherSettingsViewControllerProtocol?

    func numberOfRows(in section: Int) -> Int {
        OtherSettings.allCases.count
    }

    func setting(at indexPath: IndexPath) -> OtherSettingViewModel {
        let setting = OtherSettings.allCases[indexPath.row]
        let isLast = setting == .buildVersion

		var viewModel = OtherSettingViewModel(
			title: setting.title,
			value: setting.value,
			kind: setting.kind,
			isLast: isLast
		)

		if setting == .deleteCachedDocuments {
			viewModel.action = {
				Notification.post(.shouldClearCachedDocuments)
				self.controller?.alert(message: "form.done".localized)
			}
		}

		return viewModel
    }

    func saveForm() {
        // Save settings
    }
}



