import Foundation

final class Deallocator {
	var closure: () -> Void

	init(_ closure: @escaping () -> Void) {
		self.closure = closure
	}

	deinit {
		closure()
	}
}

enum ObjcAssociatedProperty {
	static func get<T>(
		from holder: Any,
		for key: UnsafeRawPointer,
		withDefaultValueIfNil: (() -> T)? = nil
	) -> T? {
		guard let value = objc_getAssociatedObject(holder, key), value is T else {
			if let defaultValue = withDefaultValueIfNil?() {
				self.set(defaultValue, to: holder, for: key)
				return defaultValue
			}
			return nil
		}

		return value as? T
	}

	static func `set`<T>(
		_ object: T,
		to holder: Any,
		for key: UnsafeRawPointer,
		_ policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
	) {
		objc_setAssociatedObject(
			holder,
			key,
			object,
			policy
		)
	}

	static func remove(
		_ key: UnsafeRawPointer,
		from holder: Any,
		_ policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
	) {
		objc_setAssociatedObject(
			holder,
			key,
			nil,
			policy
		)
	}
}
