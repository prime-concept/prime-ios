import Foundation
import YandexMobileMetrica

enum AnalyticsReporterProvider {
    case yandexMetrica
}

class AnalyticsReporter {
    static func reportEvent(
        _ event: String,
        parameters: [String: Any] = [:],
        provider: AnalyticsReporterProvider
    ) {
        switch provider {
        case .yandexMetrica:
            YMMYandexMetrica.reportEvent(event, parameters: parameters)
        }

        DebugUtils.shared.log(sender: self, "Logging \(provider) event \(event), parameters: \(String(describing: parameters))")
    }
}
