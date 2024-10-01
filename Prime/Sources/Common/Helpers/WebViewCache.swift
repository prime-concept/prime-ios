import WebKit

extension WKWebView {
	private var webArchiveDirectoryURL: URL? {
		self.directoryURL("WebArchives")
	}

	func saveWebArchive(_ fileName: String) {
		if #available(iOS 14.0, *) {
			self.createWebArchiveData { result in
				self.save(result: result, fileName: fileName, type: "webarchive")
			}
		}
	}

	@discardableResult
	func loadWebArchive(_ fileName: String) -> Bool {
		guard let fileURL = self.webArchiveDirectoryURL?.appendingPathComponent("\(fileName).webarchive") else {
			DebugUtils.shared.log(sender: self, "Error loading web archive: \(fileName)")
			return false
		}

		do {
			let archiveData = try Data(contentsOf: fileURL)
			self.load(archiveData, mimeType: "application/x-webarchive", characterEncodingName: "", baseURL: fileURL)
			DebugUtils.shared.log(sender: self, "Web archive loaded from: \(fileURL.path)")
			return true
		} catch {
			DebugUtils.shared.log(sender: self, "Error loading web archive: \(error.localizedDescription)")
			return false
		}
	}
}

extension WKWebView {
	private var pdfDirectoryURL: URL? {
		self.directoryURL("WKWebView-PDF")
	}

	func savePDF(_ fileName: String) {
		if #available(iOS 14.0, *) {
			self.createPDF { result in
				self.save(result: result, fileName: fileName, type: "pdf")
			}
		}
	}

	@discardableResult
	func loadPDF(_ fileName: String) -> Bool {
		guard let fileURL = self.webArchiveDirectoryURL?.appendingPathComponent("\(fileName).webarchive") else {
			DebugUtils.shared.log(sender: self, "Error loading PDF: \(fileName)")
			return false
		}

		do {
			let archiveData = try Data(contentsOf: fileURL)
			self.load(archiveData, mimeType: "application/pdf", characterEncodingName: "", baseURL: fileURL)
			DebugUtils.shared.log(sender: self, "PDF archive loaded from: \(fileURL.path)")
			return true
		} catch {
			DebugUtils.shared.log(sender: self, "Error loading PDF: \(error.localizedDescription)")
			return false
		}
	}
}


extension WKWebView {
	private func directoryURL(_ name: String) -> URL? {
		let fileManager = FileManager.default

		guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return nil
		}

		let webArchiveDirectoryURL = documentDirectory.appendingPathComponent(name)

		// Create the WebArchives directory if it doesn't exist
		if !fileManager.fileExists(atPath: webArchiveDirectoryURL.path) {
			try? fileManager.createDirectory(
				at: webArchiveDirectoryURL,
				withIntermediateDirectories: true,
				attributes: nil
			)
		}

		return webArchiveDirectoryURL
	}

	private func save(result: Result<Data, Error>, fileName: String, type: String) {
		switch result {
			case .success(let archiveData):
				guard let fileURL = self
					.webArchiveDirectoryURL?
					.appendingPathComponent("\(fileName).\(type)") else {
					DebugUtils.shared.log(sender: self, "Error creating \(type) data: \(fileName)")
					return
				}

				do {
					try archiveData.write(to: fileURL)
					DebugUtils.shared.log(sender: self, "\(type) saved at: \(fileURL.path)")
				} catch {
					DebugUtils.shared.log(sender: self, "Error saving \(type): \(error.localizedDescription)")
				}
			case .failure(let error):
				DebugUtils.shared.log(sender: self, "Error creating \(type) data: \(error.localizedDescription)")
		}
	}
}
