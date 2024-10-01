import Foundation
import PromiseKit
import SwiftKeychainWrapper

protocol FirebasePushNotificationServiceProtocol: AnyObject {
    func registerToken() -> Promise<EmptyResponse>
    func update(token: String)
	func clearToken()
}

final class FirebasePushNotificationService: FirebasePushNotificationServiceProtocol {
    private enum Keys: String, CaseIterable {
        case token
    }

    private let endpoint: PushEndpointProtocol
    private let keychainDefault = KeychainWrapper.standard

    private(set) var firebaseToken: String? {
        get {
            guard let jsonData = self.keychainDefault.data(forKey: Keys.token.rawValue) else {
                return nil
            }
            let jsonDecoder = JSONDecoder()
            return try? jsonDecoder.decode(String.self, from: jsonData)
        }
        set {
            let jsonEncoder = JSONEncoder()
            guard let jsonData = try? jsonEncoder.encode(newValue) else {
                return
            }
            self.keychainDefault.set(jsonData, forKey: Keys.token.rawValue)
        }
    }

	// Оставляем shared, это безопасно, тк тут нет меняющегося стейта
	static let shared = FirebasePushNotificationService(endpoint: PushEndpoint())

    init(endpoint: PushEndpointProtocol) {
        self.endpoint = endpoint
    }

    func registerToken() -> Promise<EmptyResponse> {
        if let token = self.firebaseToken {
            return DispatchQueue.global().promise {
                self.endpoint.register(token: token).promise
            }
        } else {
			return Promise(error: Endpoint.Error(.requestRejected, details: "Missing token"))
        }
    }

    func update(token: String) {
        self.firebaseToken = token
    }

	func clearToken() {
		self.keychainDefault.removeObject(forKey: Keys.token.rawValue)
	}
}
