import Foundation
import ObjectiveC

func delay(_ delay: Int, _ closure: @escaping () -> Void) {
	let deadline = DispatchTime.now() + TimeInterval(delay)
	DispatchQueue.main.asyncAfter(deadline: deadline, execute: closure)
}

func delay(_ delay: TimeInterval, _ closure: @escaping () -> Void) {
	let deadline = DispatchTime.now() + delay
	DispatchQueue.main.asyncAfter(deadline: deadline, execute: closure)
}

func delay(_ delay: TimeInterval, _ closure: @escaping @autoclosure () -> Void) {
    let deadline = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: closure)
}

func every(_ delay: TimeInterval, _ closure: @escaping () -> Void) {
	let deadline = DispatchTime.now() + delay
	DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
		closure()
		every(delay, closure)
	})
}

func onMain(closure: @escaping () -> Void) {
	DispatchQueue.main.async(execute: closure)
}

func onGlobal(closure: @escaping () -> Void) {
	DispatchQueue.global().async(execute: closure)
}

/// Executes async code until some condition is met. If not met, calls the retry token to continue.
/// attempt(every: 5, maxCount: 10){ retry in
/// 	networkRequest {
/// 		if error {
/// 			retry()
///			} else { ... }
///		}
///	}
func attempt(
	on queue: DispatchQueue? = nil,
	after timeout: TimeInterval = 0,
    every seconds: TimeInterval = 0,
    maxCount: UInt? = nil,
	onAttemptsExceeded: (() -> Void)? = nil,
    _ work: @escaping (@escaping () -> Void) -> Void
) {
	var retriesLeft: UInt?
	if let maxCount = maxCount {
		if maxCount == 0 {
			onAttemptsExceeded?()
			return
		}
		retriesLeft = maxCount - 1
	}

    let retrier = {
        delay(seconds) {
            attempt(
				on: queue,
				after: 0,
				every: seconds,
				maxCount: retriesLeft,
				onAttemptsExceeded: onAttemptsExceeded,
				work
			)
        }
    }

	delay(timeout){
		guard let queue = queue else {
			work(retrier)
			return
		}

		queue.async {
			work(retrier)
		}
	}
}

@discardableResult
func with<T>(_ something: T, configBlock: (T) -> Void) -> T {
	configBlock(something)
	return something
}

func mostFit<T>(_ items: T?..., by criteria: (T, T) -> Bool) -> T? {
	items.compactMap { $0 }.sorted(by: criteria).first
}

func clamp<T: Comparable>(_ lower: T, _ value: T, _ upper: T) -> T {
	max(lower, min(value, upper))
}
