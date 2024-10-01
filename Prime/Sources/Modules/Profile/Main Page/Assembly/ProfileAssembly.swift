import UIKit

final class ProfileAssembly: Assembly {
    private let onProfileFetched: ((Profile) -> Void)
	private var shouldPrefetchProfile = false

	init(
		shouldPrefetchProfile: Bool = false,
		onProfileFetched: @escaping ((Profile) -> Void))
	{
        self.onProfileFetched = onProfileFetched
		self.shouldPrefetchProfile = shouldPrefetchProfile
    }

	func make() -> UIViewController {
        let authService = LocalAuthService()
        let presenter = ProfilePresenter(
            profileEndpoint: ProfileEndpoint(authService: authService),
            docsEndpoint: DocumentsEndpoint(authService: authService),
            discountsEndpoint: DiscountsEndpoint(authService: authService),
            contactsEndpoint: ContactsEndpoint(authService: authService),
            analyticsReporter: AnalyticsReportingService(),
            walletService: WalletService(),
            onProfileFetched: self.onProfileFetched
        )
        let controller = ProfileViewController(
            presenter: presenter,
            title: Localization.localize("profile.me")
        )
        presenter.controller = controller
		if self.shouldPrefetchProfile {
			_ = controller.view
		}
        return controller
    }
}
