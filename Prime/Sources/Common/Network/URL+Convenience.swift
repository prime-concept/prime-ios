import Foundation

extension URL {
	subscript(queryItem name: String) -> String? {
		get {
			let urlComponents = URLComponents(string: self.absoluteString)
			let queryItems = urlComponents?.queryItems
			let item = queryItems?.first { $0.name == name }?.value
			return item
		}
		set {
			guard var urlComponents = URLComponents(string: self.absoluteString) else {
				return
			}
			var queryItems = urlComponents.queryItems ?? []
			var containsItem = false
			queryItems = queryItems.map { item in
				if item.name == name {
					containsItem = true
					return URLQueryItem(name: name, value: newValue)
				}
				return item
			}
			if !containsItem {
				queryItems.append(URLQueryItem(name: name, value: newValue))
			}
			urlComponents.queryItems = queryItems
			if let url = urlComponents.url {
				self = url
			}
		}
	}
}

extension URL {
	func createWithSubdirectoriesIfNeeded() throws {
		var isDirectory = ObjCBool(false)
		let exists = FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory)
		if exists {
			return
		}
		var directoryURL = self
		if !isDirectory.boolValue {
			directoryURL = directoryURL.deletingLastPathComponent()
		}

		try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
	}
}
