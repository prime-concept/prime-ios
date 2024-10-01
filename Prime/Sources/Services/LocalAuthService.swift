import Foundation

extension Notification.Name {
    static let loggedIn = Notification.Name("loggedIn")
    static let loggedOut = Notification.Name("loggedOut")
	static let smsCodeVerified = Notification.Name("smsCodeVerified")
	static let pinCodeConfirmed = Notification.Name("pinCodeConfirmed")
    static let cardNumberVerified = Notification.Name("cardNumberVerified")
	
	static let notAMember = Notification.Name("notAMember")

	static let shouldClearCache = Notification.Name("shouldClearCache")
	static let shouldClearTasks = Notification.Name("shouldClearTasks")
	static let shouldClearCachedDocuments = Notification.Name("shouldClearCachedDocuments")

	static let willRefreshToken = Notification.Name("willRefreshToken")
	static let didRefreshToken = Notification.Name("didRefreshToken")
	static let didChangeToken = Notification.Name("didChangeToken")
	static let failedToRefreshToken = Notification.Name("failedToRefreshToken")

	static let mainPageEntered = Notification.Name("mainPageEntered")
	static let mainPageLeft = Notification.Name("mainPageLeft")
}

protocol LocalAuthServiceProtocol {
    var isAuthorized: Bool { get }
	var isOnMainPage: Bool { get }
	
    var user: Profile? { get }
    var token: AccessToken? { get }

    func auth(user: Profile, accessToken: AccessToken)
    func update(token: AccessToken)
	func update(user: Profile)

	func removePinAndToken()
    func removeAuthorization()
	
	var pinCode: String? { get set }
	var phoneNumberUsedForAuthorization: String? { get set }
}

final class LocalAuthService: LocalAuthServiceProtocol {
    private enum AuthKeys: String, CaseIterable {
        case user
        case pinCode
		case phoneNumber
		case accessToken
    }

	init() {
		Notification.onReceive(.loggedIn, .loggedOut) { [weak self] notification in
			self?.isLoggedIn = notification.name == .loggedIn
		}
	}

	static var tokenNeedsToBeRefreshed = true {
		didSet {
            if tokenNeedsToBeRefreshed {
                DebugUtils.shared.log(sender: self, "TOKEN NEEDS TO BE REFRESHED")
            } else {
                DebugUtils.shared.log(sender: self, "DID REFRESH TOKEN: ", Self.shared.accessToken as Any)
            }

			Notification.post(
				tokenNeedsToBeRefreshed ? .willRefreshToken : .didRefreshToken,
				userInfo: [
                    "access_token": Self.shared.accessToken?.accessToken as Any,
                    "refresh_token": Self.shared.accessToken?.refreshToken as Any,
                ]
			)
		}
	}

	// Оставляем shared, это безопасно, тк тут только вычисляемые проперти
	static let shared = LocalAuthService()

    private let keychain = MemoryCachedKeychainWrapper.shared

	var isOnMainPage: Bool = false {
		didSet {
			let name: Notification.Name = isOnMainPage ? .mainPageEntered : .mainPageLeft
			Notification.post(name)
		}
	}

	private(set) var isLoggedIn = false

    private var accessToken: AccessToken? {
		get {
            let token: AccessToken? = self.keychain.value(forKey: AuthKeys.accessToken.rawValue)
            return token
		}
		set {
			if newValue == nil {
				self.keychain.removeObject(forKey: AuthKeys.accessToken.rawValue)
				return
			}
			let oldToken = self.accessToken?.accessToken
			if oldToken != newValue?.accessToken {
				Notification.post(.didChangeToken)
			}
			self.keychain.set(value: newValue, forKey: AuthKeys.accessToken.rawValue)
		}
    }

    var isAuthorized: Bool {
        self.accessToken != nil
    }

    private(set) var user: Profile? {
		get {
            self.keychain.value(forKey: AuthKeys.user.rawValue)
		}
		set {
			if newValue == nil {
				self.keychain.removeObject(forKey: AuthKeys.user.rawValue)
			} else {
				self.keychain.set(value: newValue, forKey: AuthKeys.user.rawValue)
			}
		}
    }

    var token: AccessToken? {
        self.accessToken
    }

    // MARK: - User authentication operations

	func poke() {
		LocalAuthService.tokenNeedsToBeRefreshed = false
	}

    func auth(user: Profile, accessToken: AccessToken) {
        self.user = user
        self.accessToken = accessToken
		
		self.poke()
    }

    func update(token: AccessToken) {
        self.accessToken = token
		self.poke()
    }

	func update(user: Profile) {
		self.user = user
	}

	func removePinAndToken() {
		self.keychain.removeObject(forKey: AuthKeys.pinCode.rawValue)
		self.keychain.removeObject(forKey: AuthKeys.accessToken.rawValue)
	}

    func removeAuthorization() {
        AuthKeys.allCases.forEach {
            self.keychain.removeObject(forKey: $0.rawValue)
        }
		LocalAuthService.tokenNeedsToBeRefreshed = true
    }

    // MARK: - Pin operations

	var pinCode: String? {
		get {
			self.keychain.value(forKey: AuthKeys.pinCode.rawValue)
		}
		set {
			if newValue == nil {
				self.keychain.removeObject(forKey: AuthKeys.pinCode.rawValue)
				return
			}
			self.keychain.set(value: newValue, forKey: AuthKeys.pinCode.rawValue)
		}
	}

	#if TINKOFF
	var inMemoryPhoneNumberUsedForAuthorization: String?
	#endif

	var phoneNumberUsedForAuthorization: String? {
		get {
			self.keychain.value(forKey: AuthKeys.phoneNumber.rawValue)
		}
		set {
			if newValue == nil {
				self.keychain.removeObject(forKey: AuthKeys.phoneNumber.rawValue)
				return
			}
			self.keychain.set(value: newValue, forKey: AuthKeys.phoneNumber.rawValue)
		}
	}
}
