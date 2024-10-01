import UIKit

final class ProfileSettingsAssembly: Assembly {
    private let profile: Profile
    private let onProfileChange: ProfileChange

    init(profile: Profile, onProfileChange: @escaping ProfileChange) {
        self.profile = profile
        self.onProfileChange = onProfileChange
    }

    func make() -> UIViewController {
        let presenter = ProfileSettingsPresenter(
            profile: self.profile,
            onProfileChange: self.onProfileChange
        )
        let controller = ProfileSettingsViewController(
            presenter: presenter,
            title: Localization.localize("settings")
        )
        presenter.controller = controller
        return controller
    }
}
