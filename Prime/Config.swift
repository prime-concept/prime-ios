import Foundation

// swiftlint:disable force_unwrapping
enum Config {
	static var isDebugEnabled: Bool {
		get { self.bool(for: "isDebugEnabled", or: Bundle.isTestFlightOrSimulator)}
		set { storage.set(newValue, forKey: "isDebugEnabled") }
	}
	
	static let storage = UserDefaults.groupShared

	private static let logUDKey = "IS_LOG_ENABLED"
	private static let debugUDKey = "IS_DEBUG_ENABLED"
	private static let prodUDKey = "IS_PROD_ENABLED"
	private static let alertsUDKey = "ARE_DEBUG_ALERTS_ENABLED"
	private static let verboseLogUDKey = "IS_VERBOSE_LOG_ENABLED"

	static var primePassBasePath = crmEndpoint + "/artoflife/v4/api/primepass"
	static var primePassHostessBasePath = crmEndpoint + "/artoflife/v4/api/hostes"
	static var navigatorBasePath = crmEndpoint + "/artoflife/v4/api/navigator"

	static let deepLinkPath: String = "$deeplink_path"
	static let deepLinkCustomURL: String = "$custom_url"
	static let deepLinkCanonicalURL: String = "$canonical_url"

	static let termsOfUseImageName = "legal_info_terms"
	static let privacyPolicyImageName = "legal_info_privacy"

	static var branchLinkHost: String {
		resolve("primeconcept.co.uk")
	}

	static var crmEndpoint: String {
		resolve(prod: "https://api.primeconcept.co.uk", stage: "https://demo.primeconcept.co.uk")
	}

	static var ptEndpoint: String {
		resolve(prod: "https://primetraveller.technolab.com.ru",
				stage: "https://primetraveller-stage.navigator.technolab.com.ru")
	}

	static var ptToken: String {
		resolve(prod: "7014c078-898c-425d-b60f-cf1aa90fb10c",
				stage: "1bc8b7cb-d198-4f65-b9d5-e96ef527608d")
	}

	static var chatEndpoint: String {
		resolve(prod: "https://chat.primeconcept.co.uk", stage: "https://demo.primeconcept.co.uk")
	}

	static let chatBaseURL = URL(string: "\(chatEndpoint)/chat-server/v3_1")!

	static let chatStorageURL = URL(string: "\(chatEndpoint)/storage")!

	static var walletEndpoint: String {
		resolve(prod: "https://primeconcept.co.uk", stage: "https://demo.primeconcept.co.uk")
	}

	static var wineEndpoint: String {
		resolve(prod: "https://wine2.primeconcept.co.uk", stage: "https://wine3-demo.primeconcept.co.uk")
	}

	static var flowersEndpoint: String {
		resolve(prod: "https://flowers3.primeconcept.co.uk",
				stage: "https://flowers3-stage.primeconcept.co.uk")
	}

	static var isLogEnabled: Bool {
		get { self.bool(for: logUDKey, or: isDebugEnabled)}
		set { storage.set(newValue, forKey: debugUDKey) }
	}

	static var isProdEnabled: Bool {
		get {
			self.bool(for: prodUDKey, or: Config.defaultsToProd)
		}
		set {
			storage.set(newValue, forKey: prodUDKey)
		}
	}

	static var areDebugAlertsEnabled: Bool {
		get { self.bool(for: alertsUDKey) }
		set { storage.set(newValue, forKey: alertsUDKey) }
	}

	static var isVerboseLogEnabled: Bool {
		get { self.bool(for: verboseLogUDKey) }
		set { storage.set(newValue, forKey: verboseLogUDKey) }
	}

	static func bool(for key: String, or defaultValue: Bool = false) -> Bool {
		let value: Bool? = storage.object(forKey: key) as? Bool
		if value == nil {
			storage.set(defaultValue, forKey: key)
		}
		return value ?? defaultValue
	}

	static func resolve<T>(_ same: T) -> T {
		resolve(prod: same, stage: same)
	}

	static func resolve<T>(prod: T, stage: T) -> T {
		isProdEnabled ? prod : stage
	}

	static func reset() {
		self.isProdEnabled = Config.defaultsToProd
		self.isDebugEnabled = Bundle.isTestFlightOrSimulator
		self.isLogEnabled = self.isDebugEnabled
		self.areDebugAlertsEnabled = false
		self.isVerboseLogEnabled = false
	}
}
