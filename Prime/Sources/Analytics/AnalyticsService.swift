import Foundation
import YandexMobileMetrica

final class AnalyticsService {
    func setupAnalytics() {
		let key = Config.yandexMetricaKey
		if let configuration = YMMYandexMetricaConfiguration(apiKey: key) {
			configuration.crashReporting = false
			onGlobal {
				YMMYandexMetrica.activate(with: configuration)
			}
		}
    }
}
