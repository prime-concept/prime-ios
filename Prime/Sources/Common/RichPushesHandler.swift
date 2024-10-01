import UserNotifications

extension Notification.Name {
	static let chatSDKDidMarkMessagesAsSeen = Notification.Name("chatSDKDidMarkMessagesAsSeen")
}

final class RichPushesHandler {
	private var contentHandler: ((UNNotificationContent) -> Void)?
	private var bestAttemptContent: UNMutableNotificationContent?

	private lazy var decoder = JSONDecoder()

	private var retriesWaitingForInternet = [() -> Void]()

	private static let replyTemplate: String = """
	{_REPLY_TO_ID_
	  "status" : "NEW",
	  "content" : "_TEXT_",
	  "source" : "CHAT",
	  "channelId" : "_CHANNEL_ID_",
	  "meta" : {},
	  "type" : "TEXT",
	  "timestamp" : "_TIMESTAMP_",
	  "guid" : "_GUID_"
	}
	"""

	private var isRetryingRequest = false
	private var requestsToRetry = [(Bool) -> Void]()
	private var retryInterval = 1

	private var retriesWaitingInternet: [(URLRequest, () -> Void)] = []

	init() {
		Notification.onReceive(.networkReachabilityChanged) { _ in
            guard NetworkMonitor.shared.isConnected, !self.retriesWaitingInternet.isEmpty else {
				return
			}

			let retries = self.retriesWaitingInternet
			self.retriesWaitingInternet.removeAll()
			retries.forEach { $0.1() }
		}

		Notification.onReceive(.chatSDKDidMarkMessagesAsSeen) { [weak self] notification in
			guard var guids = notification.userInfo?["guids"] as? [String] else {
				return
			}

			guids = guids.map{ $0.lowercased() }
			self?.removeNotifications(guids: guids)
		}
	}

	func didReceive(
		_ request: UNNotificationRequest,
		withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
	) {
		DebugUtils.shared.log(sender: self, "\(#function) DID RECEIVE PUSH!\n\(request.content.userInfo)")

		self.showPushButtons()

		self.contentHandler = contentHandler
		self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

		let willFetchImage = self.fetchImage(for: request) { [weak self] data in
			guard let self = self, let data = data,
				  let attachment = try? UNNotificationAttachment(data: data) else {
				self?.contentHandler?(request.content)
				return
			}

			self.bestAttemptContent?.attachments = [attachment]
			self.contentHandler?(self.bestAttemptContent ?? request.content)
		}

		if willFetchImage {
			return
		}

		self.fetchText(for: request) { text in
			self.bestAttemptContent?.body = text ?? request.content.body
			self.contentHandler?(self.bestAttemptContent ?? request.content)
		}
	}

	func serviceExtensionTimeWillExpire() {
		// Called just before the extension will be terminated by the system.
		// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
		if let contentHandler = self.contentHandler,
		   let bestAttemptContent =  self.bestAttemptContent
		{
			contentHandler(bestAttemptContent)
		}
	}

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		didReceive response: UNNotificationResponse,
		withCompletionHandler completionHandler: @escaping () -> Void
	) {
		switch response.actionIdentifier {
			case "REPLY_MESSAGE_CATEGORY":
				self.makeMessageSeen(response: response)
				self.sendReply(response: response)
			default:
				break
		}
		completionHandler()
	}

	func removeNotifications(guids: [String]) {
		UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
			let pushesToRemove = notifications.filter { push in
				let messageGuid = (push.request.content.userInfo[AnyHashable("message_guid")] as? String)
				guard let messageGuid else {
					return false
				}
				return guids.contains(messageGuid)
			}

			let pushGuidsToRemove = pushesToRemove.map(\.request.identifier)

			UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: pushGuidsToRemove)
		}
	}

	private func showPushButtons() {
		if LocalAuthService.shared.token == nil {
			return
		}

		let replyAction = UNTextInputNotificationAction(
			identifier: "REPLY_MESSAGE_CATEGORY",
			title: "rich.pushes.hint".localized,
			textInputButtonTitle: "rich.pushes.send".localized,
			textInputPlaceholder: "rich.pushes.hint".localized)

		let pushNotificationButtons = UNNotificationCategory(
			identifier: "REPLY_MESSAGE_CATEGORY",
			actions: [replyAction],
			intentIdentifiers: [],
			options: [])

		UNUserNotificationCenter.current().setNotificationCategories([pushNotificationButtons])
	}

	@discardableResult
	private func fetchImage(for request: UNNotificationRequest, completion: ((Data?) -> Void)?) -> Bool {
		guard let urlString = request.content.userInfo["image_url"] as? String,
			  let url = URL(string: urlString) else {
			return false
		}

		self.executeRequest(url) { data in
			completion?(data)
		}

		return true
	}

	@discardableResult
	private func fetchText(for request: UNNotificationRequest, completion: ((String?) -> Void)?) -> Bool {
		guard let deeplinkURL = request.content.userInfo["url"] as? String else {
			self.contentHandler?(request.content)
			return false
		}

		let channelId = self.channelId(from: deeplinkURL)
		let timestamp = Int(Date().timeIntervalSince1970)

		var urlString = Config.chatBaseURL.appendingPathComponent("messages").absoluteString
		urlString += "?channelId=\(channelId)&direction=OLDER&limit=5&t=\(timestamp)"

		guard let url = URL(string: urlString) else {
			self.contentHandler?(request.content)
			return false
		}

		self.executeRequest(url) { data in
			guard let data = data else {
				completion?(nil)
				return
			}

			let guid = request.content.userInfo["message_guid"] as? String
			let response = try? self.decoder.decode(MessagesResponse.self, from: data)

			var message = [String: AnyDecodable]()

			if let guid = guid {
				message = response?.items.first { self.guid(from: $0) == guid } ?? message
			} else {
				message = response?.items.first { self.content(from: $0) != nil } ?? message
			}

			let text = self.content(from: message)

			completion?(text)
		}

		return true
	}

	private func channelId(from deeplinkURL: String) -> String {
		let channelId = deeplinkURL.first(match: "(?<=\\/)\\d+")
		let userName = LocalAuthService.shared.user?.username ?? ""
		let channelIdArgument = channelId == nil ? "N\(userName)" : "T\(channelId!)"
		return channelIdArgument
	}

	private func sendReply(response: UNNotificationResponse) {
		let text = (response as? UNTextInputNotificationResponse)?.userText as? String
		let deeplinkURL = response.notification.request.content.userInfo["url"] as? String

		guard let text, let deeplinkURL else {
			return
		}

		let channelId = self.channelId(from: deeplinkURL)
		let timestamp = Int(Date().timeIntervalSince1970).description
		let guid = UUID().uuidString

		let replyGuid = response.notification.request.content.userInfo["message_guid"] as? String
		let replyReplacement = replyGuid == nil ? "" : "\n\"replyToId\" : \"\(replyGuid!)\","

		let result = Self.replyTemplate
			.replacingOccurrences(of: "_TEXT_", with: text)
			.replacingOccurrences(of: "_CHANNEL_ID_", with: channelId)
			.replacingOccurrences(of: "_TIMESTAMP_", with: timestamp)
			.replacingOccurrences(of: "_GUID_", with: guid)
			.replacingOccurrences(of: "_REPLY_TO_ID_", with: replyReplacement)

		let data = result.data(using: .utf8)

		let url = Config.chatBaseURL.appendingPathComponent("messages").absoluteString + "?t=\(timestamp)"
		self.executeRequest(URL(string: url)!, method: "POST", data: data)
	}

	private func makeMessageSeen(response: UNNotificationResponse) {
		let guid = response.notification.request.content.userInfo["message_guid"]
		guard let guid = guid as? String else {
			return
		}

		var url = Config.chatBaseURL.appendingPathComponent("messages").absoluteString
		url.append("?guid=\(guid)&status=SEEN")
		self.executeRequest(URL(string: url)!, method: "PUT") { [weak self] data in
			let url = Config.chatBaseURL.appendingPathComponent("totalUnreadCount")
			self?.executeRequest(url, method: "GET") { data in
				guard let data = data,
					let string = String(data: data, encoding: .utf8),
					let badge = Int(string) else {
					return
				}

				let content = UNMutableNotificationContent()
				content.badge = NSNumber(integerLiteral: badge)

				let notification = UNNotificationRequest(
					identifier: UUID().uuidString,
					content: content,
					trigger: nil
				)

				let notificationCenter = UNUserNotificationCenter.current()
				notificationCenter.add(notification) { (error) in
				   if error != nil {
					  // Handle any errors.
				   }
				}
			}
		}
	}

	private func executeRequest(
		_ url: URL,
		method: String = "GET",
		data: Data? = nil,
		completion: ((Data?) -> Void)? = nil
	) {
		guard let accessToken = LocalAuthService.shared.token?.accessToken else {
			DebugUtils.shared.log(sender: self, "[ERROR] \(#function) NO ACCESS TOKEN!")
			completion?(nil)
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = method
		request.addValue("*/*", forHTTPHeaderField: "Accept")
		request.addValue("ru", forHTTPHeaderField: "Accept-Language")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue(Config.chatClientAppID, forHTTPHeaderField: "X-Client-Id")
		request.addValue(accessToken, forHTTPHeaderField: "X-Access-Token")
		request.addValue(accessToken, forHTTPHeaderField: "access_token")
		request.addValue(accessToken, forHTTPHeaderField: "Authorization")
		request.addValue(self.userAgent, forHTTPHeaderField: "User-Agent")
		request.httpBody = data

		let cURL = request.cURL
		DebugUtils.shared.log(sender: self, "WILL EXECUTE REQUEST \(cURL)")

		URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
			guard let self else {
				DebugUtils.shared.log("[\(Self.self)][ERROR] \(#function) SELF IS GONE!")
				return
			}

			let responseString = data == nil ? "" : String(data: data!, encoding: .utf8)
			let logMessage = "[\(Self.self)] RESPONSE FOR \(cURL) IS \(responseString ?? ""), ERROR: \(error?.localizedDescription ?? "")"

			DebugUtils.shared.log(sender: self, logMessage)

			let error = self.inferError(from: response, error: error)

			DebugUtils.shared.log(sender: self, "INFERRED ERROR: \(error?.localizedDescription ?? "")")

			guard let error = error else {
				self.retryInterval = 1
				completion?(data)
				return
			}

			let retryBlock: (Bool) -> Void = { [weak self] success in
				if success {
					self?.executeRequest(url, method: method, data: data, completion: completion)
				} else {
					completion?(data)
				}
			}

			delay(self.retryInterval) {
				self.resolveConnectionDifficulties(
					request, error: error, retryBlock: retryBlock
				)
			}
		}.resume()
	}

	private func inferError(from response: URLResponse?, error: Error?) -> Error? {
		if let error = error {
			return error
		}

		let statusCode = (response as? HTTPURLResponse)?.statusCode
		guard let statusCode = statusCode, statusCode == 401 else {
			return nil
		}

		let nsError = NSError(
			domain: "RICH PUSHES REQUEST ERROR",
			code: statusCode,
			userInfo: [NSLocalizedDescriptionKey: "invalid access token"]
		)

		return nsError
	}

	private let userAgent: String = {
		if let info = Bundle.main.infoDictionary {
			let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
			let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
			let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

			return "\(executable)/\(appVersion)(\(appBuild))"
		}
		return "Rich push service"
	}()

	func resolveConnectionDifficulties(_ request: URLRequest,
			   error: Error,
			   retryBlock: @escaping (Bool) -> Void
	) {
		self.retryInterval += 1
		self.retryInterval = min(self.retryInterval, 60)

		if NetworkMonitor.shared.isConnected {
			guard error.isExpiredToken else {
				retryBlock(false)
				return
			}

			self.requestsToRetry.append(retryBlock)

			if self.isRetryingRequest { return }
			self.isRetryingRequest = true

			self.refreshToken { [weak self] success in
				self?.requestsToRetry.forEach { $0(success) }
				self?.requestsToRetry.removeAll()
				self?.isRetryingRequest = false
			}

			return
		}

		if self.retriesWaitingInternet.contains(where: { $0.0 == request }) {
			return
		}

		let retryBlock = { retryBlock(true) }

		self.retriesWaitingInternet.append((request, retryBlock))
	}

	private func refreshToken(_ requestRetryBlock: @escaping (Bool) -> Void) {
		DebugUtils.shared.log(sender: self, "WILL REFRESH TOKEN")
		guard let request = self.tokenRefreshUrlRequest() else {
			requestRetryBlock(false)
			return
		}

		URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
			guard let self else { return }

			let responseString = data == nil ? "" : String(data: data!, encoding: .utf8)
			let logMessage = "[\(Self.self)] DID REFRESH TOKEN \(responseString ?? ""), ERROR: \(error?.localizedDescription ?? "")"
			
			DebugUtils.shared.log(sender: self, logMessage)


			if let error = error {
				if error.isExpiredToken || error.isChangedPinToken {
					requestRetryBlock(false)
					return
				}

				delay(self.retryInterval) {
					self.resolveConnectionDifficulties(
						request, error: error, retryBlock: requestRetryBlock
					)
				}
				return
			}

			self.retryInterval = 1

			guard let data = data,
				  let token = try? self.decoder.decode(AccessToken.self, from: data),
				  token.isValid else {
				requestRetryBlock(false)
				return
			}

			LocalAuthService.shared.update(token: token)
			requestRetryBlock(true)
		}.resume()
	}

#if TINKOFF
	private func tokenRefreshUrlRequest() -> URLRequest? {
		let endpoint = "\(Config.tinkoffAuthEndpoit)/token"

		guard let refreshToken = LocalAuthService.shared.token?.refreshToken,
			  let url = URL(string: endpoint) else {
			return nil
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("*/*", forHTTPHeaderField: "Accept")
		request.addValue("ru", forHTTPHeaderField: "Accept-Language")
		request.addValue(self.userAgent, forHTTPHeaderField: "User-Agent")
		request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

		let authString = "\(Config.clientID):\(Config.clientSecret)"
		let authString64 = authString.data(using: .utf8)!.base64EncodedString()
		request.addValue("Bearer \(authString64)", forHTTPHeaderField: "Authorization")

		let body = "refresh_token=\(refreshToken)&client_id=\(Config.clientID)&grant_type=refresh_token"
		request.httpBody = body.data(using: .utf8)

		return request
	}
#else
	private func tokenRefreshUrlRequest() -> URLRequest? {
		let endpoint = "\(Config.crmEndpoint)/artoflife/v4/oauth/token"

		guard let username = LocalAuthService.shared.user?.username,
			  let pinCode = LocalAuthService.shared.pinCode,
			  let url = URL(string: endpoint) else {
			return nil
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("*/*", forHTTPHeaderField: "Accept")
		request.addValue("ru", forHTTPHeaderField: "Accept-Language")
		request.addValue(self.userAgent, forHTTPHeaderField: "User-Agent")
		request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

		let authString = "\(Config.clientID):\(Config.clientSecret)"
		let authString64 = authString.data(using: .utf8)!.base64EncodedString()
		request.addValue("Basic \(authString64)", forHTTPHeaderField: "Authorization")
		let body = "username=\(username)&password=\(pinCode)&grant_type=password&scope=private"

		request.httpBody = body.data(using: .utf8)

		return request
	}
#endif
}

extension UNNotificationAttachment {
	convenience init(data: Data, options: [NSObject: AnyObject]? = nil) throws {
		let fileManager = FileManager.default
		let temporaryFolderName = ProcessInfo.processInfo.globallyUniqueString
		let temporaryFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
			.appendingPathComponent(temporaryFolderName, isDirectory: true)

		try fileManager.createDirectory(
			at: temporaryFolderURL,
			withIntermediateDirectories: true,
			attributes: nil
		)
		let imageFileIdentifier = UUID().uuidString + ".jpg"
		let fileURL = temporaryFolderURL.appendingPathComponent(imageFileIdentifier)
		try data.write(to: fileURL)
		try self.init(identifier: imageFileIdentifier, url: fileURL, options: options)
	}
}

private extension RichPushesHandler {
	private func guid(from dictionary: [String: AnyDecodable]) -> String? {
		dictionary["guid"]?.value as? String
	}

	private func content(from dictionary: [String: AnyDecodable]) -> String? {
		let content = dictionary["content"]?.value

		if let content = content as? String {
			return content
		}

		if let content = content as? [String: AnyDecodable] {
			if let message = content["message"]?.value as? [String: AnyDecodable] {
				if let body = message["message"]?.value as? [String: AnyDecodable] {
					if let content = body["content"]?.value as? String {
						return content
					}
				}
			}
		}
		return nil
	}
}

private struct MessagesResponse: Decodable {
	let items: [[String: AnyDecodable]]
}
