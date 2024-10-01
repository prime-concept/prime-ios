import UIKit

final class ProfileEditAssembly: Assembly {
    private let profile: Profile
    private let onProfileChange: ProfileChange

    init(profile: Profile, onProfileChange: @escaping ProfileChange) {
        self.profile = profile
        self.onProfileChange = onProfileChange
    }

    func make() -> UIViewController {
        let presenter = ProfileEditPresenter(
            profileEndpoint: ProfileEndpoint(authService: LocalAuthService()),
            profile: self.profile,
            onProfileChange: self.onProfileChange
        )
        let controller = ProfileEditViewController(presenter: presenter)
        presenter.controller = controller
        return controller
    }
}
