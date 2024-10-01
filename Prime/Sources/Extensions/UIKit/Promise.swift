//import PromiseKit
//
///// Wait for all promises in a set to fulfill.
//public func when<U: Thenable, V: Thenable, W: Thenable, X: Thenable, Y: Thenable, Y1: Thenable, Y2: Thenable>(fulfilled pu: U, _ pv: V, _ pw: W, _ px: X, _ py: Y, _ py1: Y1, _ py2: Y2) -> Promise<(U.T, V.T, W.T, X.T, Y.T, Y1.T, Y2.T)> {
//	return _when2([pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid(), py.asVoid(), py1.asVoid(), py2.asVoid()]).map(on: nil) { (pu.value!, pv.value!, pw.value!, px.value!, py.value!, py1.value!, py2.value!) }
//}
//
//private func _when2<U: Thenable>(_ thenables: [U]) -> Promise<Void> {
//	var countdown = thenables.count
//	guard countdown > 0 else {
//		return .value(Void())
//	}
//
//	let rp = Promise<Void>()
//
//#if PMKDisableProgress || os(Linux)
//	var progress: (completedUnitCount: Int, totalUnitCount: Int) = (0, 0)
//#else
//	let progress = Progress(totalUnitCount: Int64(thenables.count))
//	progress.isCancellable = false
//	progress.isPausable = false
//#endif
//
//	let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: .concurrent)
//
//	for promise in thenables {
//		promise.pipe { result in
//			barrier.sync(flags: .barrier) {
//				switch result {
//				case .rejected(let error):
//					if rp.isPending {
//						progress.completedUnitCount = progress.totalUnitCount
//						rp.box.seal(Result<Void>.rejected(error))
//					}
//				case .fulfilled:
//					guard rp.isPending else { return }
//					progress.completedUnitCount += 1
//					countdown -= 1
//					if countdown == 0 {
//						rp.box.seal(Result<Void>.fulfilled(()))
//					}
//				}
//			}
//		}
//	}
//
//	return rp
//}
