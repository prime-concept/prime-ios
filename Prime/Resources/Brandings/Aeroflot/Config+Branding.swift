import Foundation

// swiftlint:disable force_unwrapping
extension Config {
	static let bannersAppID = "AEROFLOT"
	static let hostAppBundleId = "com.prime.app.aeroflot"

	static let defaultsToProd = true
	
	static let aeroticketsEnabled = true
	static let promoCategoriesEnabled = true
	static let addToWalletEnabled = true
	static let aviaModuleEnabled = false
	static let bannersEnabled = true
	static let vipLoungeEnabled = true
	static let voiceMessagesEnabled = false
    
	static let appStoreURL = URL(string: "https://apps.apple.com/ru/app/platinum-concierge-club/id1234916890")

	static let assistantPhoneNumber = "+74957925655"

	static let clubWebsiteURL = "https://www.aeroflot.ru/ru-ru/afl_bonus/platinum_to_flight"
	static let clubPhoneNumber = "+7(495)792-56-55"

    static let chatClientAppID = "primeplatinumiOS"
    static let shouldShowOnboarding = false

    static let appUrlSchemePrefix = resolve("primeplatinum")
	static let sharingDeeplink = "\(appUrlSchemePrefix)://sharing"
	static let sharingGroupName = "group.com.prime.app.aeroflot.sharing"
	static let splashScreenColor = 0x202020

	static let utmSource = resolve("prime_aeroflot")
    static let primeTravellerAppVersion = resolve("2")
	
	static var yandexMetricaKey: String {
		resolve(
			prod: "bee72640-9af4-46d1-99e7-3533d0b0aa04",
			stage: "fb4246b0-e980-4705-b6d6-945c47bc4276"
		)
	}
	
    static let shouldOpenPrimeTravellerFirst = false
    static let isPersonalDataEditingAvailable = false
    static let isQRCodeHidden = false
    static let isClubCardNumberBelowUserName = true

    static var clientID: String {
		resolve(prod: "QWVyb2Zsb3RJT1NOZXdHZW4=", stage: "UHJpbWVJdGFseU5ldw==")
    }

    static var clientSecret: String {
		resolve(prod: "S2V5QWVyb2Zsb3RJT1NOZXdHZW5fMjIxMTIwMjMxMyU1OEA=",
				stage: "UHJpbWVJdGFseU5ld1Bhc3MyMDExMjAyMw==")
    }
	
    static var travellerEndpoint: String {
        resolve(prod: "https://aeroflot-traveller.concierge.ru/", stage: "https://aeroflot-traveller-stage.concierge.ru")
    }
}
