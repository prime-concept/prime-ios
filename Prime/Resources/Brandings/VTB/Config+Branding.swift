import Foundation

// swiftlint:disable force_unwrapping
extension Config {
    static let bannersAppID = "VTB" //write Danil delos in restuarant chat
	static let hostAppBundleId = "me.prime.primeconcierge"

	static let defaultsToProd = true

	static let aeroticketsEnabled = true
	static let promoCategoriesEnabled = true
	static let addToWalletEnabled = true
	static let aviaModuleEnabled = true
	static let bannersEnabled = true
	static let vipLoungeEnabled = true
	static let voiceMessagesEnabled = false

	static let appStoreURL = URL(string: "https://apps.apple.com/ru/app/platinum-concierge-club/id6470516934")

	static let assistantPhoneNumber = "+74955040900"

	static let clubWebsiteURL = "https://primeconcept.co.uk"
	static let clubPhoneNumber = "+74955040900" //from VTB old app

    static var chatClientAppID: String { Self.clientID }
    static let shouldShowOnboarding = false

	// Вернуть после разовой акции
    static let appUrlSchemePrefix = resolve("primeconcierge")
	static let sharingDeeplink = "\(appUrlSchemePrefix)://sharing"
	static let sharingGroupName = "group.me.prime.primeconcierge.Share"
	static let splashScreenColor = 0x202020

	static let utmSource = resolve("prime_vtb")  //
    static let primeTravellerAppVersion = resolve("2")
	
	static var yandexMetricaKey: String {
		resolve(
			prod: "094d5235-7baf-4b11-9ac9-78c516c2cbe0",
			stage: "fb4246b0-e980-4705-b6d6-945c47bc4276" // from I'm Prime
		)
	}

    static let shouldOpenPrimeTravellerFirst = true
    static let isPersonalDataEditingAvailable = false
    static let isQRCodeHidden = false
    static let isClubCardNumberBelowUserName = false

    static var clientID: String {
		resolve(prod: "Wv3E2T5QD9M=", // from VTB old app
                stage: "IiRLCSQnjaE=") // stage got from  I'm Prime, need to correct
    }

    static var clientSecret: String {
		resolve(prod: "H72SjqpmkdkRM4wMWwnuLTW+NUXoR/C8p5LK7+i5v4k=", // from VTB old app
				stage: "qMGeagwcF0BHpd0Zl2Xcdc4b10hYOP55g7DeHECUHGs=") // stage got from  I'm Prime, need to correct
    }

    static var travellerEndpoint: String {
        resolve(prod: "https://prime.travel", stage: "https://stage-refactored.prime.travel")
    }
}
