import Foundation

final class ResponseCacheService {
	// Оставляем shared, но данные чистим при разлогине/очистке кэша
	static let shared = ResponseCacheService()

	private lazy var cacheRootURL = try? FileManager.default.url(
		   for: .documentDirectory,
		   in: .userDomainMask,
		   appropriateFor: nil,
		   create: true
	).appendingPathComponent("response_cache")

	init() {
		Notification.onReceive(.loggedOut, .shouldClearCache) { [weak self] _ in
			self?.clearCache()
		}
	}

	func write(data: Data, for url: URL?, parameters: [String: Any]?) {
		guard let url = url, let data = data.aesEncrypt(key: "e3b0c44298fc1c149afbf4c8996fb92") else {
			return
		}

		let filePath = self.filePath(for: url, parameters: parameters)
		let fileURL = URL(fileURLWithPath: filePath)

		do {
			let directoryPath = fileURL.deletingLastPathComponent()
				.absoluteString
				.withSanitizedFileSchema

			if FileManager.default.fileExists(atPath: directoryPath),
			   FileManager.default.fileExists(atPath: filePath) {
				try data.write(to: fileURL, options: .atomic)
				return
			}

			try FileManager.default.createDirectory(
				atPath: directoryPath,
				withIntermediateDirectories: true
			)

			FileManager.default.createFile(atPath: filePath, contents: data)
		} catch {
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) write failed",
					parameters: error.asDictionary
				)

			DebugUtils.shared.log(error)
		}
	}

	func data(for url: URL, parameters: [String: Any]?) -> Data? {
		let filePath = self.filePath(for: url, parameters: parameters)
		let fileURL = URL(fileURLWithPath: filePath)

		do {
			return try Data(contentsOf: fileURL).aesDecrypt(key: "e3b0c44298fc1c149afbf4c8996fb92")
		} catch {
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) fetch failed",
					parameters: error.asDictionary
				)

			DebugUtils.shared.log(error)
			return nil
		}
	}

	private func filePath(for url: URL, parameters: [String: Any]? = nil) -> String {
		var path = self.cacheRootURL?.absoluteString ?? ""

		url.host.flatMap { host in
			path.append("/")
			path.append(host.replacingOccurrences(of: ".", with: "/"))
		}

		path.append(url.path)

		if let sha256 = self.pathFragmentFrom(query: url.query)?.sha256_hex {
			path.append("/")
			path.append(sha256)
		}

		if let sha256 = parameters?.orderedStringRepresentation.sha256_hex {
			path.append("/")
			path.append(sha256)
		}

		path.append("/Data.dat")
		path = path.withSanitizedFileSchema

		return path
	}

	private func pathFragmentFrom(query: String?) -> String? {
		guard let query = query else {
			return nil
		}

		let queryComponents = query.split(separator: "&").map { String($0) }
		var queryDictionary = [String: String]()

		for component in queryComponents {
			let pair = component.split(separator: "=").map { String($0) }
			if pair.count != 2 {
				continue
			}
			queryDictionary[pair[0]] = pair[1]
		}

		var result = ""

		for key in queryDictionary.keys.sorted(by: <) where key != "t" {
			result.append("/")
			result.append(key)
			result.append("/")
			result.append(queryDictionary[key] ?? "")
		}
		result = result.sha256_hex
		return result
	}

	@objc
	private func clearCache() {
		guard let path = self.cacheRootURL?.absoluteString else {
			return
		}
		do {
			try FileManager.default.removeItem(atPath: path.withSanitizedFileSchema)
		} catch {
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) clear cache failed",
					parameters: error.asDictionary
				)
			DebugUtils.shared.log(error)
		}
	}
}

private extension String {
	var withSanitizedFileSchema: String {
		self.replacingOccurrences(of: "^file:\\/+", with: "/", options: .regularExpression)
	}
}
