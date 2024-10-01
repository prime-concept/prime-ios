import Foundation
import UserNotifications

protocol OnboardingServiceProtocol {
    func requestPermissionForNotifications()
    func requestPermissionForLocation()
    func getPageViewModels() -> [OnboardingPageViewModel]
}

class OnboardingService: OnboardingServiceProtocol {
    private let didShowOnboardingKey = "didShowOnboardingKey"
    private let defaults = UserDefaults.standard
    private let locationService: LocationServiceProtocol?
    private let analyticsReporter: AnalyticsReportingService?

    private var didShowOnboarding: Bool {
        get {
            self.defaults.value(forKey: self.didShowOnboardingKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.didShowOnboardingKey)
        }
    }

    init(
        locationService: LocationServiceProtocol? = nil,
        analyticsReporter: AnalyticsReportingService? = nil
    ) {
        self.locationService = locationService
        self.analyticsReporter = analyticsReporter
    }

	func requestPermissionForNotifications() {
		UNUserNotificationCenter.current().requestAppPermissions { [weak self] success in
			if success {
				self?.analyticsReporter?.pushPermissionGranted()
			}
		}
	}

    func requestPermissionForLocation() {
        self.locationService?.fetchLocation { result in
            switch result {
            case .success:
                self.analyticsReporter?.geoPermissionGranted()
            case .error:
                break
            }

			return false
        }
    }

    // TODO: - L1ON
    func getPageViewModels() -> [OnboardingPageViewModel] {
        [
            OnboardingTextContentViewModel(
                currentPageIndex: 0,
                numberOfPages: 9,
                headline: "onboarding.headline".localized.uppercased(),
                number: "1.",
                title: "onboarding.1st.page.title".localized,
                firstParagraph: "onboarding.1st.page.1st.paragraph".localized,
                secondParagraph: "onboarding.1st.page.2nd.paragraph".localized,
                subTitle: "onboarding.1st.page.subtitle".localized
            ),
            OnboardingStarContentViewModel(
                currentPageIndex: 1,
                numberOfPages: 9,
                image: "novikov",
                title: "onboarding.2nd.page.title".localized,
                firstParagraph: "onboarding.2nd.page.1st.paragraph".localized
            ),
            OnboardingTextContentViewModel(
                currentPageIndex: 2,
                numberOfPages: 9,
                headline: "onboarding.headline".localized.uppercased(),
                number: "2.",
                title: "onboarding.3rd.page.title".localized,
                firstParagraph: "onboarding.3rd.page.1st.paragraph".localized,
                secondParagraph: "onboarding.3rd.page.2nd.paragraph".localized,
                dotTexts: [
                    "onboarding.3rd.page.1st.dot".localized,
                    "onboarding.3rd.page.2nd.dot".localized,
                    "onboarding.3rd.page.3rd.dot".localized,
                    "onboarding.3rd.page.4th.dot".localized
                ],
                subTitle: "onboarding.3rd.page.subtitle".localized,
                image: "partners"
            ),
            OnboardingStarContentViewModel(
                currentPageIndex: 3,
                numberOfPages: 9,
                image: "sobchak",
                title: "onboarding.4th.page.title".localized,
                firstParagraph: "onboarding.4th.page.1st.paragraph".localized,
                secondParagraph: "onboarding.4th.page.2nd.paragraph".localized
            ),
            OnboardingTextContentViewModel(
                currentPageIndex: 4,
                numberOfPages: 9,
                headline: "onboarding.headline".localized.uppercased(),
                number: "3.",
                title: "onboarding.5th.page.title".localized,
                firstParagraph: "onboarding.5th.page.1st.paragraph".localized,
                image: "partners2"
            ),
            OnboardingStarContentViewModel(
                currentPageIndex: 5,
                numberOfPages: 9,
                image: "rappoport",
                title: "onboarding.6th.page.title".localized,
                firstParagraph: "onboarding.6th.page.1st.paragraph".localized,
                secondParagraph: "onboarding.6th.page.2nd.paragraph".localized
            ),
            OnboardingTextContentViewModel(
                currentPageIndex: 6,
                numberOfPages: 9,
                headline: "onboarding.headline".localized.uppercased(),
                number: "4.",
                title: "onboarding.7th.page.title".localized,
                dotTexts: [
                    "onboarding.7th.page.1st.dot".localized,
                    "onboarding.7th.page.2nd.dot".localized,
                    "onboarding.7th.page.3rd.dot".localized,
                    "onboarding.7th.page.4th.dot".localized,
                    "onboarding.7th.page.5th.dot".localized,
                    "onboarding.7th.page.6th.dot".localized,
                    "onboarding.7th.page.7th.dot".localized
                ]
            ),
            OnboardingStarContentViewModel(
                currentPageIndex: 7,
                numberOfPages: 9,
                image: "bondarchuk",
                title: "onboarding.8th.page.title".localized,
                firstParagraph: "onboarding.8th.page.1st.paragraph".localized,
                secondParagraph: "onboarding.8th.page.2nd.paragraph".localized
            ),
            OnboardingTextContentViewModel(
                currentPageIndex: 8,
                numberOfPages: 9,
                headline: "onboarding.headline".localized.uppercased(),
                number: "5.",
                title: "onboarding.9th.page.title".localized,
                firstParagraph: "onboarding.9th.page.1st.paragraph".localized,
                secondParagraph: "onboarding.9th.page.2nd.paragraph".localized,
                image: "stars-icon"
            )
        ]
    }
}

extension UNUserNotificationCenter {
	func requestAppPermissions(_ onGranted: ((Bool) -> Void)?) {
		self.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] (granted, error) in
			guard granted else {
				DebugUtils.shared.alert(sender: self, "Request PUSH NOTIFICATIONS Authorization Failed!")
				error.some { error in
					DebugUtils.shared.alert(sender: self, "Request PUSH NOTIFICATIONS error: (\(error), \(error.localizedDescription))")
				}
				onGranted?(false)
				return
			}

			let replyAction = UNTextInputNotificationAction(identifier: "REPLY_MESSAGE_CATEGORY", title: "Reply", options: [])
			let quickReplyCategory = UNNotificationCategory(identifier: "REPLY_MESSAGE_CATEGORY", actions: [replyAction], intentIdentifiers: [], options: [])
			
			UNUserNotificationCenter.current().setNotificationCategories([quickReplyCategory])

			onGranted?(true)
		}
	}
}
