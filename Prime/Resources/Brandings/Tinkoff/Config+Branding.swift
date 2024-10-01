import Foundation

// swiftlint:disable force_unwrapping
extension Config {
	static let bannersAppID = "TINKOFF" // Айди приложения для бэкенда Баннеров. Передается Данилу Деллосу.
	static let hostAppBundleId = "me.prime.PrimeConciergeClub" // Нужно для экстеншенов
	static let appUrlSchemePrefix = resolve("ptinkoff") // URL-схема приложения, как в plist-e
	static let sharingDeeplink = "\(appUrlSchemePrefix)://sharing"
	static let sharingGroupName = "group.me.prime.PrimeConciergeClub.sharing" // Нужно для экстеншенов

	// Айдишник (6470922259) берется из урла вашего Брендинга в Аппстор Коннекте
	static let appStoreURL = URL(string: "https://apps.apple.com/ru/app/platinum-concierge-club/id6470922259")

	static let assistantPhoneNumber = "+7(495)287-99-90" // Телефон ассистента по умолчанию, узнать у ПМ
	static let clubPhoneNumber = "+7(495)287-99-90" // Телефон куба, узнать у ПМ
	static let clubWebsiteURL = "https://primeconcept.co.uk" // Сайт куба, узнать у ПМ

	static let splashScreenColor = 0x000000 // Цвет сплэша, нужен для экстеншенов

	static let defaultsToProd = true

	// Всяческие настройки брендов.
	// Если ваш брендинг не суперкастомный или суперВИП-овый, то скорее всего вас устроят эти значения.
	static let aeroticketsEnabled = true
	static let promoCategoriesEnabled = true
	static let addToWalletEnabled = true
	static let aviaModuleEnabled = true
	static let bannersEnabled = true
	static let vipLoungeEnabled = true
	static let voiceMessagesEnabled = false
	static let shouldOpenPrimeTravellerFirst = false
	static let isPersonalDataEditingAvailable = false
	static let isQRCodeHidden = false
    static let isClubCardNumberBelowUserName = false
	static let shouldShowOnboarding = false
	static var chatClientAppID: String { Self.clientID }

	static var clientID: String {  // Айдишник приложения на бэке
		resolve(prod: "vtO5z8JMIoc=", stage: "dGlua29mZl9ib3Q=" ) // Узнавать у разрабов бэка (CRM)
	}

	static var clientSecret: String { // "Пароль" приложения на бэке
		resolve(prod: "", stage: "")  // Узнавать у разрабов бэка (CRM). Сейчас секреты в тинькове убраны по настоянию бэка.
	}

	static var yandexMetricaKey: String { // Настройки Яндекс-метрики
		resolve(prod: "84bee28c-90b3-42ef-b3bf-ec20191a3d0d", stage: "fb4246b0-e980-4705-b6d6-945c47bc4276")
	}

	static var travellerEndpoint: String { // Адрес для веб-вью ПраймТревелера - сайт в шторке на главной.
		resolve(prod: "https://prime.travel", stage: "https://stage-refactored.prime.travel") // Узнавать у ПМ
	}

	static var tinkoffAuthEndpoit: String {
		resolve(
			prod: "https://tinkoff.concierge.ru/auth",
			stage: "https://demo.primeconcept.co.uk/tinkoff/auth"
		)
	}

	static let utmSource = resolve("prime_tinkoff")
	static let primeTravellerAppVersion = resolve("2")
}
