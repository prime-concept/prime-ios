import Foundation
import UIKit

class VersionService {
	// Оставляем shared, это безопасно, тк этот сервис не несет в себе данных пользователя
	static let shared = VersionService()

	private init() {
		Notification.onReceive(UIApplication.didBecomeActiveNotification) { _ in
			Self.shared.checkMinimalVersion()
		}
	}

	private static var minVersion: String?

	private static var isOutdated: Bool {
		guard let minVersion = Self.minVersion else {
			return false
		}

		var minVersionComponents = minVersion
			.components(separatedBy: ".")
			.compactMap{ Int($0) }

		let currentVersion = Bundle.main.releaseVersionNumber
		var currentVersionComponents = currentVersion
			.components(separatedBy: ".")
			.compactMap{ Int($0) }

		let delta = minVersionComponents.count - currentVersionComponents.count

		if delta > 0 {
			for _ in 0..<abs(delta) {
				currentVersionComponents.append(0)
			}
		} else if delta < 0 {
			for _ in 0..<abs(delta) {
				minVersionComponents.append(0)
			}
		}

		for i in 0..<currentVersionComponents.count {
			if currentVersionComponents[i] > minVersionComponents[i] {
				return false
			}

			if currentVersionComponents[i] < minVersionComponents[i] {
				DebugUtils.shared.log("[FATAL] APP VERSION IS OUTDATED! CURRENT \(currentVersion), MIN: \(minVersionComponents)")
				return true
			}
		}

		return false
	}

	private static func alertVersionIsOutdated() {
		AlertPresenter.alert(message: "app.version.outdated".localized, actionTitle: "common.ok".localized, onAction:  {
			if let url = Config.appStoreURL {
				UIApplication.shared.open(url)
			}
		})
	}

	func checkMinimalVersion() {
		if Self.isOutdated {
			Self.alertVersionIsOutdated()
			return
		}

		VersionEndpoint.shared.retrieve().promise.done { version in
			Self.minVersion = version.minSupportedVersion
		}.ensure {
			if Self.isOutdated {
				Self.alertVersionIsOutdated()
			}
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) checkMinimalVersion failed",
					parameters: error.asDictionary
				)
		}
	}
}
