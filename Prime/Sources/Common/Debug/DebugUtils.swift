import UIKit

//swiftlint:disable all
class DebugUtils {
	// Оставляем shared, это безопасно, тк логи пишем вне зависимости от сессии юзера
	static let shared = DebugUtils()

	var isOnMainPage = false
	
	private let loggingQueue = DispatchQueue(label: "DebugUtils.shared.loggingQueue")
	
	var logFileName: String = {
		let dictionary = Bundle.main.infoDictionary ?? [:]
		let appName = dictionary["CFBundleName"] ?? "App"
		let version = dictionary["CFBundleShortVersionString"] ?? "Version"
		let build = dictionary["CFBundleVersion"] ?? "Build"

		let fullName = "\(appName)_\(version)(\(build)).log"
		return fullName
	}()

	lazy var logFilePath: String? = {
		let fileManager = FileManager.default

		guard let logsDirectoryURL = fileManager
			.urls(for: .documentDirectory, in: .userDomainMask)
			.first?
			.appendingPathComponent("Logs") else {
			return nil
		}

		do {
			try fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
		} catch {
			print("\(DebugUtils.self) FAILED TO CREATE LOGS DIR: \(error)")
			return nil
		}

		let fileURL = logsDirectoryURL.appendingPathComponent(self.logFileName)
		let filePath = fileURL.absoluteString.replacing(regex: "^file:///", with: "/")

		if fileManager.fileExists(atPath: filePath) {
			return filePath
		}

		let success = fileManager.createFile(atPath: filePath, contents: nil)

		if success {
			return filePath
		}

		return nil
	}()

	private lazy var logFileHandle: FileHandle? = {
		if let path = self.logFilePath {
			return FileHandle(forWritingAtPath: path)
		}
		return nil
	}()

	private func appendToLog(_ string: String) {
		self.loggingQueue.async {
			let date = Date().string("dd.MM.yyyy HH-mm-ss(SSSS)")
			let logEntry = "\(date):\n\(string)"

			guard let logFileHandle = self.logFileHandle else {
				print("\(DebugUtils.self) FAILED TO ACCESS LOG FILE! WRITING MEM-ONLY:")
				print(logEntry + "\n\n")
				return
			}

			guard let data = logEntry.data(using: .utf8) else {
				return
			}

			logFileHandle.seekToEndOfFile()
			logFileHandle.write(data)
		}
	}

	var log: String {
		guard let path = self.logFilePath else {
			return "ERROR READING/WRITING LOGS"
		}

		let fileHandle = FileHandle(forReadingAtPath: path)

		guard let handle = fileHandle else {
			return ""
		}

		let data = handle.readDataToEndOfFile()
		fileHandle?.closeFile()
		
		return String(data: data, encoding: .utf8) ?? ""
	}

	func log(
		sender: AnyObject? = nil,
		_ items: Any...,
		separator: String = " ",
		terminator: String = "\n",
		prefix: String? = "PRIME:",
		mayLogToGoogle: Bool = true
	) {
		var prefix = prefix != nil ? prefix! + " " : ""
		if let sender = sender {
			prefix.append("[\(type(of: sender))] \(Unmanaged.passUnretained(sender).toOpaque()) ")
		}
		let message = "[APP LOG] " + prefix + message(from: items, separator: separator).appending(terminator)

		self.loggingQueue.async {
			if Bundle.isTestFlightOrSimulator {
				print(message)
				self.appendToLog(message)
			}
            
			if mayLogToGoogle {
				FirebaseUtils.logToCrashlytics(message)
				FirebaseUtils.logToGoogleRealtimeDatabase(message)
			}
		}
	}

	func message(from items: Any..., separator: String = " ") -> String {
		let message = items.deepMap{ $0 }.reduce("") {
			if let string = $1 as? String {
				return $0 + string + separator
			}
			return $0
		}
		return message
	}

	func clearLog() {
		self.loggingQueue.async {
			self.logFileHandle?.truncateFile(atOffset: 0)
		}
	}
}
//swiftlint:enable all
