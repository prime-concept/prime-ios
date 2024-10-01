import Foundation

class Debouncer {
    private let timeout: TimeInterval
    private var timer = Timer()
    private var action: (() -> Void)?
	private(set) var isTriggered = false

	@ThreadSafe
	private var pendingCompletions = [(() -> Void)?]()

	init(timeout: TimeInterval, isReady: Bool = true, action: @escaping () -> Void) {
        self.timeout = timeout
		self.action = { [weak self] in
			action()
			self?.pendingCompletions.forEach {
				$0?()
			}
			self?.pendingCompletions.removeAll()
			self?.isTriggered = false
		}
		if isReady {
			self.reset()
		}
    }

	func reset(addCompletion completion: (() -> Void)? = nil) {
		self.timer.invalidate()
		self.pendingCompletions.append(completion)
		self.timer = .scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
			self?.action?()
        }
		self.isTriggered = true
    }

	func fireNow() {
		if self.timer.isValid {
			self.timer.invalidate()
			self.action?()
		}
	}

	deinit {
		self.timer.invalidate()
		self.action = nil
	}
}

class Throttler {
	private let timeout: TimeInterval
	private var action: () -> Void

	private(set) var mayExecute = true
	private var pendingExecutionExists = false
	private var executesPendingAfterCooldown = true

	init(
		timeout: TimeInterval,
		executesPendingAfterCooldown: Bool = true,
		action: @escaping () -> Void
	) {
		self.executesPendingAfterCooldown = executesPendingAfterCooldown
		self.timeout = timeout
		self.action = action
	}

	func execute() {
		guard self.mayExecute else {
			if self.executesPendingAfterCooldown {
				self.pendingExecutionExists = true
			}
			return
		}

		self.mayExecute = false

		self.action()

		delay(self.timeout) { [weak self] in
			self?.mayExecute = true

			guard let self, self.pendingExecutionExists else {
				return
			}
			
			self.pendingExecutionExists = false
			self.execute()
		}
	}

	func reset() {
		self.mayExecute = true
	}
}

class BatchEnqueuer {
	private let maxCount: Int
	private var availablePlacesCount: Int
	private var pendingRequests: [(BatchEnqueuer) -> Void] = []

	private let lock = NSRecursiveLock()

	private var requestsCompleted = 0

	var onBatchProcessed: ((BatchEnqueuer) -> Void)?
	var onAllProcessed: ((BatchEnqueuer) -> Void)?

	private let tag: String

	init(
		tag: String = "",
		maxCount: Int = 1,
		onBatchProcessed: ((BatchEnqueuer) -> Void)? = nil,
		onAllProcessed: ((BatchEnqueuer) -> Void)? = nil
	) {
		self.maxCount = maxCount
		self.onBatchProcessed = onBatchProcessed
		self.onAllProcessed = onAllProcessed

		self.availablePlacesCount = maxCount
		self.tag = tag
	}

	func enqueue(_ block: @escaping (BatchEnqueuer) -> Void) {
		self.lock.withLock {
			self.pendingRequests.append(block)

			let mayExecute = self.availablePlacesCount > 0
            availablePlacesCount -= 1

			if mayExecute {
				self.executeNextIfPossible()
			}
		}
	}

	func runNext() {
		self.lock.withLock {
            availablePlacesCount += 1
			self.requestsCompleted += 1

			let didCompleteBatch = self.requestsCompleted % self.maxCount == 0
			let allPlacesAvailable = self.availablePlacesCount == self.maxCount

			if didCompleteBatch || allPlacesAvailable {
				self.onBatchProcessed?(self)
			}

			if self.pendingRequests.isEmpty, allPlacesAvailable {
				self.onAllProcessed?(self)
			}

			self.executeNextIfPossible()
		}
	}

	private func executeNextIfPossible() {
		self.lock.withLock {
			if self.pendingRequests.isEmpty { return }

			let block = self.pendingRequests.removeFirst()
			block(self)
		}
	}
}
