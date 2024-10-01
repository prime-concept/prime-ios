import UIKit

final class PersistableTimer {
	let timeout: Int
	var onTick: ((Int) -> Void)?

	private var secondsLeft: Int
	private var backgroundingDate: Date?
	private weak var timer: Timer?

	init(timeout: Int, onTick: ((Int) -> Void)? = nil) {
		self.timeout = timeout
		self.secondsLeft = timeout

		self.onTick = onTick

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(storeTime),
			name: UIApplication.didEnterBackgroundNotification,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(restoreTime),
			name: UIApplication.willEnterForegroundNotification,
			object: nil
		)
	}

	func start() {
		self.stop()

		self.timer = Timer.scheduledTimer(
			timeInterval: 1,
			target: self,
			selector: #selector(self.timerDidTick),
			userInfo: nil,
			repeats: true
		)
	}

	func stop() {
		self.secondsLeft = self.timeout
		self.timer?.invalidate()
		self.timer = nil
	}

	@objc
	private func storeTime() {
		self.backgroundingDate = Date()
	}

	@objc
	private func restoreTime() {
		let backgroundingDate = self.backgroundingDate ?? Date()
		let secondsInBackground = Date().timeIntervalSince(backgroundingDate)

		self.secondsLeft -= Int(secondsInBackground.rounded())

		self.backgroundingDate = nil
	}

	@objc
	private func timerDidTick() {
		self.secondsLeft -= 1
		self.onTick?(self.secondsLeft)
		if self.secondsLeft <= 0 {
			self.stop()
		}
	}
}
