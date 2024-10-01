import UIKit

final class AuthFlowFirstStepFactory {
	static func make() -> UIViewController {
		CardNumberAssembly().make()
	}
}
