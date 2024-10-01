import AVFoundation
import UIKit

typealias EmptyClosure = () -> Void

protocol PermissionServiceProtocol {
    func requestCamera(type: CameraErrorType, granted: @escaping EmptyClosure)
	func requestHomePermissionsIfNeeded(
		pushesCompletion: ((Bool) -> Void)?,
		locationCompletion: ((Bool) -> Void)?
	)

	func schedulePermissionRequest(_ block: @escaping () -> Void)
}

enum CameraErrorType: String {
    case photo

    var description: String {
        Localization.localize("permission.description.\(self.rawValue)")
    }
}

final class PermissionService: PermissionServiceProtocol {
	// Оставляем shared, это безопасно, тк Пермишшены выдаются на уровне приложения
	// и не зависят от повторного логина
	static let shared = PermissionService()

	private var pendingPermissionRequests = [() -> Void]()
	private var permissionsRequestInProgress = false

	func schedulePermissionRequest(_ block: @escaping () -> Void) {
		if self.permissionsRequestInProgress {
			self.pendingPermissionRequests.append(block)
			return
		}

		block()
	}

	func requestHomePermissionsIfNeeded(
		pushesCompletion: ((Bool) -> Void)? = nil,
		locationCompletion: ((Bool) -> Void)? = nil
	) {
		if DefaultsService.shared.hasRequestedPermissions {
			pushesCompletion?(true)
			locationCompletion?(true)
			return
		}

		self.permissionsRequestInProgress = true

		self.requestPermissionForNotifications { [weak self] success in
			pushesCompletion?(success)

			self?.requestPermissionForLocation { [weak self] success in
				locationCompletion?(success)

				self?.pendingPermissionRequests.forEach { completion in
					completion()
				}

				self?.pendingPermissionRequests.removeAll()
				self?.permissionsRequestInProgress = false
			}
		}

		DefaultsService.shared.hasRequestedPermissions = true
	}

	private func requestPermissionForNotifications(_ completion: ((Bool) -> Void)? = nil) {
		UNUserNotificationCenter.current().requestAppPermissions { success in
			AnalyticsReportingService.shared.pushPermissionGranted()
			completion?(success)
		}
	}

	private func requestPermissionForLocation(_ completion: ((Bool) -> Void)? = nil) {
		LocationService.shared.fetchLocation { result in
			switch result {
			case .success:
				AnalyticsReportingService.shared.geoPermissionGranted()
				completion?(true)
			case .error:
				completion?(false)
				break
			}
			return false
		}
	}

    func requestCamera(type: CameraErrorType, granted: @escaping EmptyClosure) {
        // swiftlint:disable all
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            granted()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { isGranted in
                // swiftlint:enable all
                DispatchQueue.main.sync {
                    if isGranted {
                        granted()
                    }
                }
            }
        case .restricted, .denied:
            self.showPermissionAlert(type: type)
        default:
            return
        }
    }

    private func showPermissionAlert(type: CameraErrorType) {
        let alert = AlertContollerFactory.makeCameraErrorController(type: type) { [weak self] in
            self?.openAppSettings()
        }

		let viewController = UIWindow.keyWindow?.rootViewController?.topmostPresentedOrSelf
		viewController?.present(alert, animated: true)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            assertionFailure("Expected to work always")
            return
        }

        UIApplication.shared.open(url)
    }
}
