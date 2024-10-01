import Foundation

// swiftlint:disable force_unwrapping
extension Config {
	static let bannersAppID = "PRIME_CLUB"
	static let hostAppBundleId = "me.prime.primeclub"

	static let defaultsToProd = true
	
	static let aeroticketsEnabled = true
	static let promoCategoriesEnabled = true
	static let addToWalletEnabled = false
	static let aviaModuleEnabled = true
	static let bannersEnabled = true
	static let vipLoungeEnabled = true
	static let voiceMessagesEnabled = false
	
    static let appStoreURL = URL(string: "https://apps.apple.com/ru/app/id6456219142")
    
    static let assistantPhoneNumber = "+74957750120"
    
    static let clubWebsiteURL = "https://primeconcept.co.uk"
    static let clubPhoneNumber = "+7(963)646-45-00"
    
    static let shouldShowOnboarding = false
    
    static let appUrlSchemePrefix = resolve("primeclub")
    static let sharingDeeplink = "\(appUrlSchemePrefix)://sharing"
    static let sharingGroupName = "group.me.prime.primeclub.sharing"
    static let splashScreenColor = 0x202020
    
    static let utmSource = resolve("prime_club") //will chnage
    static let primeTravellerAppVersion = resolve("2")
    
    static var yandexMetricaKey: String {
        resolve(
            prod: "afff5ec3-c055-4819-b4d6-a3a2691a8c27",
            stage: "fb4246b0-e980-4705-b6d6-945c47bc4276"
        )
    }
    
    static let shouldOpenPrimeTravellerFirst = true
    static let isPersonalDataEditingAvailable = true
    static let isQRCodeHidden = true
    static let isClubCardNumberBelowUserName = false

    static var clientID: String {
        resolve(prod: "UHJpbWVNb2JpbGVBcHBfMjAyM3Zlci4=",
                stage: "UHJpbWVNb2JpbGVBcHBfMjAyM3Zlci4gRGVtbw==")
    }
    
    static var chatClientAppID: String { Self.clientID }
    
    static var clientSecret: String {
        resolve(prod: "JThgP1dgMmZ2LCZRZipeUw==",
                stage: "NXIze3UkRnhNYFxMXjlXPw==")
    }
    
    static var travellerEndpoint: String {
        resolve(prod: "https://aclub.prime.travel", stage: "https://stage-aclub.prime.travel")
    }
}
