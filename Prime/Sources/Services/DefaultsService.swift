import Foundation

protocol DefaultsServiceProtocol: AnyObject {
    var appHasRunBefore: Bool { get set }
    var hasLoginBefore: Bool { get set }
    var hasRequestedPermissions: Bool { get set }
}

final class DefaultsService: DefaultsServiceProtocol {
    private enum Keys {
        static let appHasRunBeforeKey = "appHasRunBeforeKey"
        static let hasLoginBeforeKey = "hasLogonBeforeKey"
        static let hasRequestedPermissions = "hasRequestedPermissions"
    }

    private let userDefaults = UserDefaults.standard

	// Оставляем shared, это безопасно, тк здесь только вычисляемые проперти
    static let shared = DefaultsService()

    var appHasRunBefore: Bool {
        get {
            return self.userDefaults.bool(forKey: Keys.appHasRunBeforeKey)
        }
        set {
            self.userDefaults.set(newValue, forKey: Keys.appHasRunBeforeKey)
        }
    }

    var hasLoginBefore: Bool {
        get {
            return self.userDefaults.bool(forKey: Keys.hasLoginBeforeKey)
        }
        set {
            self.userDefaults.set(newValue, forKey: Keys.hasLoginBeforeKey)
        }
    }

    var hasRequestedPermissions: Bool {
        get {
            return self.userDefaults.bool(forKey: Keys.hasRequestedPermissions)
        }
        set {
            self.userDefaults.set(newValue, forKey: Keys.hasRequestedPermissions)
        }
    }
}
