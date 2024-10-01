import Foundation

extension Bundle {
	var id: String! {
		Self.main.bundleIdentifier
	}
	
	var appName: String {
        // swiftlint:disable:next force_cast
		infoDictionary?["CFBundleDisplayName"] as! String
	}
	
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "NULL"
    }

    var buildVersionNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "NULL"
    }

    var releaseVersionNumberPretty: String {
		"v\(releaseVersionNumber) (\(self.buildVersionNumber)) \(Bundle.isTestFlightOrSimulator ? "(dev)" : "")"
    }

	var releaseWithBuildVersionNumber: String {
		"\(releaseVersionNumber)_\(buildVersionNumber)"
	}

	static var isTestFlightOrSimulator: Bool {
#if targetEnvironment(simulator)
		return true
#else
		let lastPath = Bundle.main.appStoreReceiptURL?.lastPathComponent
		guard let lastPath = lastPath else {
			return true
		}

		return lastPath == "sandboxReceipt"
#endif
	}
}
