import UIKit
import SafariServices

final class SafariRouter: ModalRouter {
	init(url: URL, source: ModalRouterSourceProtocol?, delegate: SFSafariViewControllerDelegate? = nil) {
        let controller = SFSafariViewController(url: url)
		controller.preferredControlTintColor = Palette.shared.brandPrimary.rawValue
		controller.delegate = delegate
        super.init(
            source: source,
            destination: controller,
            modalPresentationStyle: .pageSheet
        )
    }
}
