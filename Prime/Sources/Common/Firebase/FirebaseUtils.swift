import Foundation
import Firebase
import FirebaseCrashlytics
import FirebaseDatabase
import FirebaseAppCheck
import DeviceKit

enum FirebaseUtils {
	static let appDBName = Bundle.main.id.replacing(regex: "\\.", with: "-")

	static var userId: String? {
		LocalAuthService.shared.user?.username ??
		LocalAuthService.shared.phoneNumberUsedForAuthorization ??
		UIDevice.current.identifierForVendor?.uuidString
	}

	static func set(userId: String) {
		Crashlytics.crashlytics().setUserID(userId)
	}

	static func logToCrashlytics(_ message: String) {
		Crashlytics.crashlytics().log(message)
	}

	static func logToGoogleRealtimeDatabase(_ message: String) {
		guard let db = Self.logsDB(userId: Self.userId) else {
			return
		}

		let time = Date().string("HH:mm:ss-SSS")
		db.child(time).setValue(message) { error, database in
			if let error {
				print("\(#function) ERROR: \(error.localizedDescription)")
			}
		}
	}

	private static var versionAndDevice: String = {
		let version = "VERSION: \(Bundle.main.releaseVersionNumberPretty)"
		let device = "DEVICE: \(Device.current.description), \(Device.current.systemName ?? "") \(Device.current.systemVersion ?? "")"
		return "\(version) \(device)".replacingOccurrences(of: "[\\.\\[\\]\\$\\#]", with: "_", options: .regularExpression)
	}()

	static func logsDB(
		year: String = Date().string("YYYY"),
		month: String = Date().string("MM"),
		day: String = Date().string("dd"),
		userId: String?
	) -> Firebase.DatabaseReference? {
		FirebaseApp.configureIfNeeded()

		let yyyyMM = "\(year)-\(month)"
		var db = Firebase.Database.database().reference()
			.child(Self.appDBName)
			.child("Logs")
			.child(yyyyMM)
			.child(day)

		if let userId, !userId.isEmpty {
			db = db.child(userId)
		}

		db = db.child(Self.versionAndDevice)

		if let uuid = UIDevice.current.identifierForVendor?.uuidString, uuid != userId {
			db = db.child(uuid)
		}

		return db
	}

	static func logsDB(
		year: String = Date().string("YYYY"),
		month: String = Date().string("MM"),
		day: String = Date().string("dd")
	) -> Firebase.DatabaseReference? {
		FirebaseApp.configureIfNeeded()

		let yyyyMM = "\(year)-\(month)"
		let db = Firebase.Database.database().reference()
			.child(Self.appDBName)
			.child("Logs")
			.child(yyyyMM)
			.child(day)

		return db
	}
}

extension FirebaseApp {
	private static var configured: Bool = false
	private static let lock = NSLock()

	static func configureIfNeeded() {
		lock.lock(); defer { lock.unlock() }

		if self.configured {
			return
		}

#if targetEnvironment(simulator)
		let providerFactory = AppCheckDebugProviderFactory()
		AppCheck.setAppCheckProviderFactory(providerFactory)
#else
		let providerFactory = PrimeAppCheckProviderFactory()
		AppCheck.setAppCheckProviderFactory(providerFactory)
#endif
		
		self.configure()
		self.configured = true
	}
}

class PrimeAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
	if #available(iOS 14.0, *) {
	  return AppAttestProvider(app: app)
	} else {
	  return DeviceCheckProvider(app: app)
	}
  }
}
