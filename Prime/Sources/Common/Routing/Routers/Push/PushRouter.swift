import UIKit

class PushRouter: SourcelessRouter, RouterProtocol {
    private var destination: UIViewController
    private var source: PushRouterSourceProtocol?

    init(
        source optionalSource: PushRouterSourceProtocol?,
        destination: UIViewController
    ) {
        self.destination = destination
        super.init()
        let possibleSource = self.currentNavigation?.topViewController
        if let source = optionalSource ?? possibleSource {
            self.source = source
        } else {
            self.source = self.window?.rootViewController
        }
    }

    func route() {
        self.source?.push(module: self.destination)
    }

	func pop() {
		self.source?.pop()
	}
}
