import UIKit

final class AuthFlowFirstStepFactory {
	static func make() -> UIViewController {
		PhoneNumberAssembly().make()
	}
}
