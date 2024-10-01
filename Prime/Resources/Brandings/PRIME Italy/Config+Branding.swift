import Foundation

// swiftlint:disable force_unwrapping
extension Config {
	static let bannersAppID = "PRIME_ITALY"
	static let hostAppBundleId = "me.prime.italy"

	static let defaultsToProd = true
	
	static let aeroticketsEnabled = true
    static let promoCategoriesEnabled = true
    static let addToWalletEnabled = true
    static let aviaModuleEnabled = true
    static let bannersEnabled = true
	static let vipLoungeEnabled = true
	static let voiceMessagesEnabled = true

	static let appStoreURL = URL(string: "https://apps.apple.com/ru/app/id6463721351")

	static let assistantPhoneNumber = "+74957925655" // Need to discuss

	static let clubWebsiteURL = "https://www.aeroflot.ru/ru-ru/afl_bonus/platinum_to_flight" // Need to discuss
	static let clubPhoneNumber = "+7(495)792-56-55" // Need to discuss

    static var chatClientAppID: String { Self.clientID }
    static let shouldShowOnboarding = false

    static let appUrlSchemePrefix = resolve("primeitaly")
    static let sharingDeeplink = "\(appUrlSchemePrefix)://sharing"
    static let sharingGroupName = "group.com.prime.italy.sharing"
    static let splashScreenColor = 0x202020
    
    static let utmSource = resolve("prime_italy")
    static let primeTravellerAppVersion = resolve("2")
    
    static var yandexMetricaKey: String {
        resolve(
            prod: "d46a5c85-2e55-4671-ba14-089e7a530ed2",
            stage: "fb4246b0-e980-4705-b6d6-945c47bc4276"
        )
    }
    
    static let shouldOpenPrimeTravellerFirst = true
    static let isPersonalDataEditingAvailable = false
    static let isQRCodeHidden = false
    static let isClubCardNumberBelowUserName = false

    static var clientID: String {
        resolve(prod: "mPwcd1mF29s=",
                stage: "ibpPnCENbvE=")
    }
    
    static var clientSecret: String {
        resolve(prod: "t5BNt8aXbfUfYrRhMZ9Bf7vxJloT1KcMo3p1L5d8AD0=",
                stage: "I3RL3LG707QxJdP79Prm3oJT1yZsPGZo3a4ewCpS8b8=")
    }
    
    static var travellerEndpoint: String {
        resolve(prod: "https://prime-italy.me/",
                stage: "https://stage.prime-italy.me/")
    }
}
