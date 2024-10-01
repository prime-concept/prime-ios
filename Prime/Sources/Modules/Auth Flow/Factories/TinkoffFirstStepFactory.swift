import UIKit

final class AuthFlowFirstStepFactory {
	static func make() -> UIViewController {
		guard let phone = LocalAuthService.shared.phoneNumberUsedForAuthorization else {
			return PhoneNumberAssembly().make()
		}
		return PhoneVerificationFactory.make(phone: phone)
	}
}
