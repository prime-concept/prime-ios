import Foundation

// swiftlint:disable force_unwrapping
extension Config {
	static let bannersAppID = "IM_PRIME"
	static let hostAppBundleId = "me.prime.artoflife"

	static let defaultsToProd = true
	
	static let aeroticketsEnabled = true
	static let promoCategoriesEnabled = true
	static let addToWalletEnabled = true
	static let aviaModuleEnabled = true
	static let bannersEnabled = true
	static let vipLoungeEnabled = true
	static let voiceMessagesEnabled = true

	static let appStoreURL = URL(string: "https://apps.apple.com/ru/app/im-prime/id1628646800")

	static let assistantPhoneNumber = "+79636464404"

	static let clubWebsiteURL = "https://primeconcept.co.uk"
	static let clubPhoneNumber = "+7(495)241-55-76"

    static let chatClientAppID = "primeiOS"
    static let shouldShowOnboarding = false
    
    static let appUrlSchemePrefix = resolve("prime")
    static let sharingDeeplink = "\(appUrlSchemePrefix)://sharing"
    static let sharingGroupName = "group.prime.sharing"
    static let splashScreenColor = 0x340F06
    
    static let utmSource = resolve("i_m_prime_application")
    static let primeTravellerAppVersion = resolve("2")
    
    static var yandexMetricaKey: String {
        resolve(
            prod: "6988795b-a99c-4b0b-803d-367a280c2354",
            stage: "fb4246b0-e980-4705-b6d6-945c47bc4276"
        )
    }
    
    static let shouldOpenPrimeTravellerFirst = false
    static let isPersonalDataEditingAvailable = true
    static let isQRCodeHidden = false
    static let isClubCardNumberBelowUserName = false

    static var clientID: String {
        resolve(prod: "bmV3IGlvcyBtb2JpbGUgYXJ0IG9mIGxpZmU=",
                stage: "4NKiHExsABs=")
    }
    
    static var clientSecret: String {
        resolve(prod: "QkNITWM9bjN3Jzc/W1ZUcA==",
                stage: "GlipT/NPtAc5m7cjhXhXB6jq2FGiDZecms6yVJbr054=")
    }
    
    static var travellerEndpoint: String {
        resolve(prod: "https://prime.travel", stage: "https://stage-refactored.prime.travel")
    }
}
