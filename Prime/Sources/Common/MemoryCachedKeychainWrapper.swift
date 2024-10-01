import SwiftKeychainWrapper

public class MemoryCachedKeychainWrapper: KeychainWrapper {
	private var cache = [String: Any]()
	private let secureDefaults = SecureUserDefaultsWrapper()

	private let lock = NSLock()

	public static let shared: MemoryCachedKeychainWrapper = {
        // swiftlint:disable:next force_cast
        let appIdentifierPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String
		let bundleId = Config.hostAppBundleId

		let accessGroup = "\(appIdentifierPrefix)\(bundleId).SharedItems"

		return MemoryCachedKeychainWrapper(
			serviceName: "PrimeSharedKeychainWrapper",
			accessGroup: accessGroup
		)
	}()

	public func set<T: Codable>(value: T, forKey key: String) {
		self.lock.lock(); defer { self.lock.unlock() }

		guard let jsonData = try? JSONEncoder().encode(value) else {
			return
		}

		self.set(jsonData, forKey: key)
		self.secureDefaults.set(value: value, forKey: key)
		self.cache[key] = value
	}

	public func value<T: Codable>(forKey key: String) -> T? {
		guard let jsonData = self.data(forKey: key),
			  let value = try? JSONDecoder().decode(T.self, from: jsonData) else {
			let cached = (cache[key] as? T) ?? self.secureDefaults.value(forKey: key)
			return cached
		}

		return value
	}

	@discardableResult
	public override func removeObject(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
		self.cache[key] = nil
		self.secureDefaults.removeObject(forKey: key)
		return super.removeObject(forKey: key, withAccessibility: accessibility)
	}

	var debugDescription: String {
		self.description
	}

	var description: String {
		"MemoryCachedKeychainWrapper. ServiceName: \(self.serviceName), AccessGroup: \(self.accessGroup ?? "")"
	}
}

private class SecureUserDefaultsWrapper {
	private let defaults = UserDefaults.groupShared

	public func set<T: Codable>(value: T, forKey key: String) {
		guard let jsonData = try? JSONEncoder().encode(value),
			  let encryptedData = jsonData.aesEncrypt(key: "Fd357aUDfibP(*-9Bcfs42") else {
			return
		}

		self.defaults.set(encryptedData, forKey: key)
	}

	public func value<T: Codable>(forKey key: String) -> T? {
		guard let jsonData = self.defaults.data(forKey: key),
			  let decryptedData = jsonData.aesDecrypt(key: "Fd357aUDfibP(*-9Bcfs42") else {
			return nil
		}

		let value = try? JSONDecoder().decode(T.self, from: decryptedData)
		return value
	}

	public func removeObject(forKey key: String) {
		self.defaults.removeObject(forKey: key)
	}
}

typealias Keychain = MemoryCachedKeychainWrapper

public extension MemoryCachedKeychainWrapper {
	static subscript<T: Codable>(value key: String) -> T? {
		get {
			Self.shared.value(forKey: key)
		}
		set {
			Self.shared.set(value: newValue, forKey: key)
		}
	}
}
