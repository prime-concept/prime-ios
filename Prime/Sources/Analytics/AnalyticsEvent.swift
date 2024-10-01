import Foundation

protocol AnalyticsReportable {
    func send(_ provider: AnalyticsReporterProvider) -> Self
}

final class AnalyticsEvent: AnalyticsReportable {
    @discardableResult
    func send(
        _ provider: AnalyticsReporterProvider = .yandexMetrica
    ) -> Self {
		self.addDefaultDataToParameters()
		AnalyticsReporter.reportEvent(self.name, parameters: self.parameters, provider: provider)
        return self
    }

    var name: String
    var parameters: [String: Any]

    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }

	private func addDefaultDataToParameters() {
		var parameters = self.parameters

		if let level = LocalAuthService.shared.user?.levelName {
			parameters["user segment (level)"] ??= level
		}

		if let username = LocalAuthService.shared.user?.username {
			parameters["username"] ??= username
		}

		self.parameters = parameters
	}
}
