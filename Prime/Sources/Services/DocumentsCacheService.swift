import Foundation

protocol DocumentsCacheServiceProtocol {
	func url(for cacheKey: String) -> URL?

	func data(cacheKey: String) -> Data?

	@discardableResult
	func save(cacheKey: String, data: Data) -> URL?
}

final class DocumentsCacheService: DocumentsCacheServiceProtocol {
	static let shared = DocumentsCacheService()

	private let cacheDirectory: URL

	private static var cacheDirectory: URL? {
		try? FileManager.default.url(
			for: .cachesDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: true
		)
	}

	init() {
		let directory = (Self.cacheDirectory ?? FileManager.default.temporaryDirectory)
			.appendingPathComponent(Bundle.main.appName, isDirectory: true)

		do {
			try FileManager.default.createDirectory(
				at: directory,
				withIntermediateDirectories: true,
				attributes: nil
			)

			self.cacheDirectory = directory
		} catch {
			DebugUtils.shared.log("DocumentsCacheService \(#function)", "cache CREATION error", error)
			self.cacheDirectory = FileManager.default.temporaryDirectory
		}

		Notification.onReceive(
			.shouldClearCachedDocuments, .shouldClearCache, .loggedOut
		) { [weak self] _ in
			self?.erase()
		}
	}

	func url(for cacheKey: String) -> URL? {
		let fileURL = self.cacheDirectory.appendingPathComponent(cacheKey)

		if FileManager.default.fileExists(atPath: fileURL.path) {
			return fileURL
		}
		return nil
	}

	func data(cacheKey: String) -> Data? {
		let fileURL = self.cacheDirectory.appendingPathComponent(cacheKey)
		guard FileManager.default.fileExists(atPath: fileURL.absoluteString) else {
			return try? Data(contentsOf: fileURL)
		}

		return nil
	}

	@discardableResult
	func save(cacheKey: String, data: Data) -> URL? {
		var fileURL = self.cacheDirectory
		let components = cacheKey.components(separatedBy: "/")
		for component in components {
			fileURL = fileURL.appendingPathComponent(component)
		}

		do {
			try fileURL.createWithSubdirectoriesIfNeeded()
			try data.write(to: fileURL, options: .atomic)
		} catch {
			DebugUtils.shared.log(
				"DocumentsCacheService \(#function)", "failed to SAVE file to cache", error, "key: \(cacheKey)"
			)

			return nil
		}

		return fileURL
	}

	fileprivate func erase() {
		do {
			try FileManager.default.removeItem(at: self.cacheDirectory)
		} catch {
			DebugUtils.shared.log(sender: self, "ERROR CLEARING DOCUMENTS CACHE! \(error)")
		}
	}
}
