import UIKit

protocol ProfileSettingsPresenterProtocol: AnyObject {
    func numberOfRows(in section: Int) -> Int
    func didSelect(at indexPath: IndexPath)
    func setting(at indexPath: IndexPath) -> ProfileSettingViewModel
}

final class ProfileSettingsPresenter: NSObject, ProfileSettingsPresenterProtocol {
    weak var controller: ProfileSettingsViewControllerProtocol?

    private var profile: Profile
    private let onProfileChange: ProfileChange

    init(profile: Profile, onProfileChange: @escaping ProfileChange) {
        self.profile = profile
        self.onProfileChange = onProfileChange
    }

    func numberOfRows(in section: Int) -> Int {
        ProfileSettings.allCases.count
    }

	//swiftlint:disable switch_case_alignment
	func didSelect(at indexPath: IndexPath) {
		let setting = ProfileSettings.allCases[indexPath.row]
		switch setting {
			case .personalData:
				let assembly = ProfileEditAssembly(profile: self.profile) { [weak self] profile in
					self?.profile = profile
					self?.onProfileChange(profile)
				}
				let profileEditController = assembly.make()
				ModalRouter(
					source: self.controller,
					destination: profileEditController,
					modalPresentationStyle: .pageSheet
				).route()
			case .expenses:
				let assembly = ExpensesAssembly()
				let expensesController = assembly.make()
				ModalRouter(
					source: self.controller,
					destination: expensesController,
					modalPresentationStyle: .pageSheet
				).route()
			case .other:
				let assembly = OtherSettingsAssembly()
				let otherSettingsController = assembly.make()
				ModalRouter(
					source: self.controller,
					destination: otherSettingsController,
					modalPresentationStyle: .pageSheet
				).route()
			case .personalDataPolicy:
				self.presentPrivacyPolicyViewController()
			case .offer:
				self.presentTermsViewController()
			case .deleteAccount:
				self.promptAccountDeletion()
			case .exit:
				self.promptLogout()
		}
	}
	//swiftlint:enable switch_case_alignment

    func setting(at indexPath: IndexPath) -> ProfileSettingViewModel {
        let setting = ProfileSettings.allCases[indexPath.row]
		let titleColor = setting == .deleteAccount ? Palette.shared.danger : Palette.shared.gray0

		let contentInsets = UIEdgeInsets(
			top: setting == .exit ? 10 : 0,
			left: setting.icon == nil ? 15 : 10,
			bottom: 0,
			right: 44
		)
        return ProfileSettingViewModel(
			icon: setting.icon,
			title: setting.title,
			titleColor: titleColor,
			contentInsets: contentInsets
		)
    }

	private func present(_ viewController: UIViewController) {
		let router = ModalRouter(
			source: self.controller,
			destination: viewController,
			modalPresentationStyle: .pageSheet
		)
		router.route()
	}

	private func presentPrivacyPolicyViewController() {
		let viewController = LegalInfoViewController(pdfContent: UIImage(named: Config.privacyPolicyImageName))
		self.present(viewController)
	}

	private func presentTermsViewController() {
		let viewController = LegalInfoViewController(pdfContent: UIImage(named: Config.termsOfUseImageName))
		self.present(viewController)
	}

	private func logout() {
		Notification.post(.loggedOut)
		Notification.post(.shouldClearCache)
	}

	private func promptLogout() {
		let alert = AlertContollerFactory.makeDestructionAlert(
			with: "profile.settings.exit.prompt".localized,
			destructTitle: "profile.settings.exit".localized,
			destruct: { [weak self] in
				self?.logout()
			}
		)
		self.controller?.present(alert, animated: true, completion: nil)
	}

	private func promptAccountDeletion() {
		let alert = AlertContollerFactory.makeDestructionAlert(
			with: "profile.settings.delete.account.prompt".localized,
			destructTitle: "profile.settings.delete".localized,
			destruct: { [weak self] in
				self?.controller?.showLoadingIndicator()
				ProfileService.shared.deleteProfile { [weak self] error in
					self?.controller?.hideLoadingIndicator()
					if error != nil {
						self?.alertAccountDeletionFailed()
						return
					}
					self?.alertAccountDeleted()
				}
			}
		)
		self.controller?.present(alert, animated: true, completion: nil)
	}
	
	private func alertAccountDeleted() {
		AlertPresenter.alert(
			message: "profile.settings.delete.account.success".localized,
			actionTitle: "common.ok".localized, onAction: { [weak self] in
				self?.logout()
			})
	}

	private func alertAccountDeletionFailed() {
		AlertPresenter.alert(
			message: "profile.settings.delete.account.failed".localized,
			actionTitle: "common.ok".localized)
	}
}
