import Foundation

protocol ProfileServiceProtocol {
	var profile: Profile? { get }
	func getProfile(cached: Bool, onComplete: @escaping (Profile?) -> Void)
}

final class ProfileService: ProfileServiceProtocol {
	private let profileEndpoint: ProfileEndpointProtocol

	@PersistentCodable(fileName: "ProfileService.profile", async: false)
	private(set) var profile: Profile? = nil

	// Оставляем shared, но очищаем Профиль при разлогине/очистке кэша
	static let shared = ProfileService(profileEndpoint: ProfileEndpoint.shared)

	init(profileEndpoint: ProfileEndpointProtocol) {
		self.profileEndpoint = profileEndpoint

		Notification.onReceive(.loggedOut, .shouldClearCache) { [weak self] _ in
			self?.profile = nil
		}
	}

	func getProfile(cached: Bool, onComplete: @escaping (Profile?) -> Void) {
		if cached, let profile = self.profile {
			onComplete(profile)
			if profile.deletedAt != nil, UserDefaults[bool: "logoutIfDeletedAtFound"] {
				Notification.post(.notAMember)
			}
			return
		}

		DispatchQueue.global().promise {
			self.profileEndpoint.getProfile().promise
		}.done(on: .main) { [weak self] profile in
			if profile.deletedAt != nil, UserDefaults[bool: "logoutIfDeletedAtFound"] {
				Notification.post(.notAMember)
				throw Endpoint.Error(.requestRejected, details: "Profile with deletedAt detected!")
			}

			self?.profile = profile
			self?.updateAuthUser(with: profile)
			onComplete(profile)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) getProfile failed",
					parameters: error.asDictionary.appending("cached", cached)
				)
			onComplete(nil)
		}
	}

	func deleteProfile(completion: @escaping (Error?) -> Void) {
		let endpoint = self.profileEndpoint

		DispatchQueue.global().promise {
			endpoint.deleteProfile().promise
		}.done(on: .main) { _ in
			completion(nil)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) deleteProfile failed",
					parameters: error.asDictionary
				)
			completion(error)
		}
	}

	private func updateAuthUser(with profile: Profile) {
		let user = LocalAuthService.shared.user
		let oldLevelName = user?.levelName
		LocalAuthService.shared.update(user: profile)

		if let oldLevelName, oldLevelName != user?.levelName {
			AnalyticsReportingService.shared.userSegmentChanged(
				from: oldLevelName, to: user?.levelName ?? "NULL"
			)
		}
	}
}

extension ProfileService {
	func update(profile: Profile) {
		self.profile = profile
	}
}
