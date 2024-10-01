import UIKit

final class PhoneVerificationFactory {
	static func make(phone: String) -> UIViewController {
		DeeplinkService.shared.setDelegate(TinkoffAuthService.shared)
		return TinkoffAuthAssembly(phone: phone).make()
	}
}
