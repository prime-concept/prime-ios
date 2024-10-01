import UIKit

final class PhoneVerificationFactory {
	static func make(phone: String) -> UIViewController {
		let assembly = SMSCodeAssembly(phone: phone) {
			let assembly = ContactPrimeAssembly(with: phone)
			let router = ModalRouter(
				source: UIViewController.topmostPresented,
				destination: assembly.make()
			)
			router.route()
		}
		return assembly.make()
	}
}
