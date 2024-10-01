import XCTest
@testable import Prime

final class BatchEnqueuerTests: XCTestCase {

	private lazy var kek1 = BatchEnqueuer(maxCount: 10)

	func test100BlocksYield10BatchCompletionsAnd1AllCompletion() {
		var batch = 0
		var all = 0

		let expectation = XCTestExpectation(description: "test100BlocksYield10BatchCompletionsAnd1AllCompletion")

		self.kek1.onBatchProcessed = { (_: BatchEnqueuer) in
			batch += 1
		}

		self.kek1.onAllProcessed = { (_: BatchEnqueuer) in
			all += 1

			if batch == 10, all == 1 {
				expectation.fulfill()
			}
		}

		for _ in 1...100 {
			self.kek1.enqueue { enqueuer in
				delay(0.01) {
                    enqueuer.runNext()
				}
			}
		}

		onGlobal {
			self.wait(for: [expectation], timeout: 5)
		}
	}

	private lazy var kek2 = BatchEnqueuer(maxCount: 10)

	func test101BlocksYield11BatchCompletionsAnd1AllCompletion() {
		var batch = 0
		var all = 0

		let expectation = XCTestExpectation(description: "test100BlocksYield10BatchCompletionsAnd1AllCompletion")

		self.kek1.onBatchProcessed = { (_: BatchEnqueuer) in
			batch += 1
		}

		self.kek1.onAllProcessed = { (_: BatchEnqueuer) in
			all += 1

			if batch == 11, all == 1 {
				expectation.fulfill()
			}
		}

		for _ in 1...101 {
			self.kek1.enqueue { enqueuer in
				delay(0.01) {
                    enqueuer.runNext()
				}
			}
		}

		onGlobal {
			self.wait(for: [expectation], timeout: 5)
		}
	}
}
