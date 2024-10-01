import Foundation
import Network

extension Notification.Name {
	static let networkReachabilityChanged = Notification.Name("networkReachabilityChanged")
}

final class NetworkMonitor {
	// Оставляем shared, это безопасно, тк монитор не несет в себе данных пользователя
	static let shared = NetworkMonitor()
	private static let queue = DispatchQueue(label: "NetworkMonitor")

	private(set) var isConnected: Bool = false
	private lazy var monitor = NWPathMonitor()

	init() {
		self.monitor.pathUpdateHandler = { path in
			self.isConnected = path.status == .satisfied
			Notification.post(.networkReachabilityChanged, userInfo: ["value": self.isConnected])
		}
		self.monitor.start(queue: Self.queue)
	}
}
