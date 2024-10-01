import Foundation

class ApplicationContainerPresenterDelegate {
	var allowsPinCodeLogin: Bool {
		UserDefaults[bool: "tinkoffPinEnabled"]
	}
	
	var mayShowBlockingPincode: Bool {
		UserDefaults[bool: "tinkoffPinEnabled"] && LocalAuthService.shared.pinCode != nil
	}
}
