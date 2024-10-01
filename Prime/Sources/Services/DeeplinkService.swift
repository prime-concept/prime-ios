import UIKit

extension Notification.Name {
    static let sharingExtentionActivated = Notification.Name("sharingExtentionActivated")
	static let shouldProcessDeeplink = Notification.Name("DeeplinkService.shouldProcessDeeplink")
}

protocol DeeplinkServiceDelegate {
	func makeDeeplink(from url: URL) -> DeeplinkService.Deeplink?
}

final class DeeplinkService {
	static let debug = "debug-6347325-ncpwb"
	static let homeHost = "home"
	static let chatHost = "chat"
	static let taskHost = "task"
	static let tasksHost = "tasks"
	static let profileHost = "profile"
	static let sharingHost = "sharing"
	static let cityguideHost = "cityguide"
    static let feedbackHost = "feedback"

    enum Deeplink: Equatable, Hashable {
		case home
		case chatMessage(String)
		case generalChat(messageGuidToOpen: String? = nil)
		case task(Int, messageGuidToOpen: String? = nil)
		case profile
        case cityguide(String)
		case tasksCompleted
		case createTask(TaskTypeEnumeration, [URLQueryItem]? = nil)
        case feedback(guid: String)
	}

	init() {
		self.subscribeToNotifications()
	}

	// Оставляем shared, но чистим стейт при разлогине
	static let shared = DeeplinkService()

	private var delegates = [DeeplinkServiceDelegate]()

	private var deeplinkNotifierDebouncer: Debouncer?

	private var blocksWaitingForActiveState = [()->Void]()

    private lazy var deeplinkThrottler = Throttler(timeout: 1) { [weak self] in
        guard let self = self else {
            return
        }

        let userInfo = ["deeplink": self.currentDeeplinks.last!]
        self.deeplinkNotifierDebouncer = nil

        self.executeOnceActive {
            Notification.post(.shouldProcessDeeplink, userInfo: userInfo)
        }
    }

	private(set) var currentDeeplinks: [Deeplink] = [] {
		didSet {
            guard self.currentDeeplinks.count > oldValue.count else {
                return
            }
            
            self.deeplinkThrottler.execute()
		}
	}

	@discardableResult
	func process(url: URL) -> Bool {
		if let url = self.deeplinkURLFrom(yandexURL: url) {
			return self.process(deeplinkUrl: url)
		}

		return self.process(deeplinkUrl: url)
	}

    private func process(deeplinkUrl: URL) -> Bool {
		guard self.isSchemeValid(in: deeplinkUrl) else {
            return false
		}

		if let deeplink = self.makeDeeplink(from: deeplinkUrl) {
			return self.process(deeplink: deeplink)
		}

		for delegate in self.delegates {
			if let deeplink = delegate.makeDeeplink(from: deeplinkUrl) {
				return self.process(deeplink: deeplink)
			}
		}

		return false
	}

	@discardableResult
	func process(deeplink: Deeplink) -> Bool {
		if self.currentDeeplinks.contains(deeplink) {
			return false
		}

		self.currentDeeplinks.append(deeplink)
		return true
	}

    func clearAction(_ deeplink: Deeplink) {
        self.currentDeeplinks.removeAll(where: { $0 == deeplink })
	}

	func clearLatestAction() {
		guard let action = self.currentDeeplinks.last else {
			return
		}

		self.clearAction(action)
	}

	func setDelegate(_ delegate: DeeplinkServiceDelegate) {
		self.delegates.removeAll()
		self.delegates.append(delegate)
	}

    // MARK: - Helpers

    private func isSchemeValid(in url: URL) -> Bool {
		url.scheme == Config.appUrlSchemePrefix
    }

	private func makeDeeplink(from url: URL) -> Deeplink? {
		switch url.host {
			case Self.debug:
				Config.isDebugEnabled = true
				return nil
			case Self.homeHost:
				return .home
			case Self.chatHost:
				if url.pathComponents.count == 2,
				   let message = url.pathComponents[1].removingPercentEncoding {
					return .chatMessage(message)
				} else {
					let messageGuid = url[queryItem: "message_guid"]
					return .generalChat(messageGuidToOpen: messageGuid)
				}
			case Self.sharingHost:
				NotificationCenter.default.post(name: .sharingExtentionActivated, object: true)
				if url.pathComponents.count == 2,
				   let message = url.pathComponents[1].removingPercentEncoding {
					return .chatMessage(message)
				} else {
					return .generalChat()
				}
			case Self.taskHost:
				let messageGuid = url[queryItem: "message_guid"]
				if let taskIDString = url.pathComponents[safe: 1], let id = Int(taskIDString) {
					return .task(id, messageGuidToOpen: messageGuid)
				}
				return nil
			case Self.tasksHost:
				if let path1 = url.pathComponents[safe: 1], path1 == "completed" {
					return .tasksCompleted
				}
				let urlComponents = URLComponents(string: url.absoluteString)
				let queryItems = urlComponents?.queryItems

				if let path1 = url.pathComponents[safe: 1], path1 == "create" {
					guard let type = url.query?.asURLQueryDictionary["type"] else {
						return .createTask(.general, queryItems)
					}

					var taskType = TaskTypeEnumeration(rawValue: type)
					if taskType == nil, let id = Int(type) {
						taskType = TaskTypeEnumeration(id: id)
					}

					return .createTask(taskType ?? .general, queryItems)
				}
				return nil
			case Self.profileHost:
				return .profile
			case Self.cityguideHost:
				var webUrl = url.path
				if !webUrl.isEmpty {
					webUrl.removeFirst()
				} else {
					return nil
				}
				return .cityguide(webUrl)
			case Self.feedbackHost:
				guard let guid = url[queryItem: "guid"] else { return nil }
				return .feedback(guid: guid)
			default:
				return nil
		}
	}

	private func executeOnceActive(_ block: @escaping (() -> Void)) {
		if UIApplication.shared.applicationState == .active {
			block()
			return
		}

		self.blocksWaitingForActiveState.append(block)
	}

	private func subscribeToNotifications() {
		Notification.onReceive(.loggedOut) { [weak self] _ in
			self?.blocksWaitingForActiveState.removeAll()
			self?.currentDeeplinks.removeAll()
		}

		Notification.onReceive(UIApplication.didBecomeActiveNotification) { _ in
			// Give time to any UI work to complete, then execute the blocks.
			delay(0.3) {
				self.blocksWaitingForActiveState.forEach { block in
					block()
				}
				self.blocksWaitingForActiveState.removeAll()
			}
		}
	}
}

extension DeeplinkService {
	private func deeplinkURLFrom(yandexURL: URL?) -> URL? {
		guard let string = yandexURL?.absoluteString else {
			return nil
		}

		let components = URLComponents(string: string)
		guard let host = components?.host?.lowercased(),
				  host.contains(regex: "redirect\\.appmetri(c|k)a") else {
			return nil
		}

		guard let path = components?.path else {
			return nil
		}

		let yandexPath = (components?.path ?? "")
		let yandexPathComponents = yandexPath.components(separatedBy: "/").skip(\.isEmpty)
		let deeplinkHost = yandexPathComponents.first
		let deeplinkPath = yandexPathComponents.dropFirst().joined(separator: "/")

		var deepLinkComponents = URLComponents()
		deepLinkComponents.scheme = Config.appUrlSchemePrefix
		deepLinkComponents.host = deeplinkHost

		// Именно так. Нельзя передать в качестве path строку без начального слэша.
		// URL из таких компонентов будет nil
		deepLinkComponents.path = "/" + deeplinkPath
		deepLinkComponents.query = components?.query

		guard let deeplinkURL = deepLinkComponents.url else {
			return nil
		}

		return deeplinkURL
	}
}

extension String {
	var asURLQueryDictionary: [String: String] {
		let pairs = self.split(separator: "&")
		var result = [String: String]()
		pairs.forEach { pair in
			let elements = pair.split(separator: "=")
			if elements.count != 2 {
				return
			}
			result[String(elements[0])] = String(elements[1])
		}

		return result
	}
}
