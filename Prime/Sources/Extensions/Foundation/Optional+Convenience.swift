import Foundation

extension Optional {
    @discardableResult
    func some(_ handler: (Wrapped) -> Void) -> Self {
        if case .some(let value) = self {
            handler(value)
        }
        return self
    }

    @discardableResult
    func none(_ handler: () -> Void) -> Self {
        if case .none = self {
            handler()
        }
        return self
    }

	/// Like flatMap, but returns default value when Wrapped is nil
	@discardableResult
	func defMap<U>(_ def: U, mapper: (Wrapped) -> U) -> U {
		guard case .some(let value) = self else {
			return def
		}
		return mapper(value)
	}

	var toStringDescription: String {
		if case .some(let wrapped) = self {
			return String(describing: wrapped)
		}
		return String(describing: self)
	}
}

infix operator ?> : ComparisonPrecedence
infix operator ?< : ComparisonPrecedence
infix operator ?>= : ComparisonPrecedence
infix operator ?<= : ComparisonPrecedence
infix operator ?+ : AdditionPrecedence
infix operator ??= : AssignmentPrecedence
infix operator |== : ComparisonPrecedence
postfix operator ^

//swiftlint:disable:next static_operator
public func ?> <T>(lhs: T?, rhs: T?) -> Bool where T: Comparable {
	guard let lhs = lhs, let rhs = rhs else {
		if lhs == nil {
			return false
		}
		return true
	}

	return lhs > rhs
}

public func ?>= <T>(lhs: T?, rhs: T?) -> Bool where T: Comparable {
	guard let lhs = lhs, let rhs = rhs else {
		if lhs == nil {
			return false
		}
		return true
	}

	return lhs >= rhs
}

//swiftlint:disable:next static_operator
public func ?< <T>(lhs: T?, rhs: T?) -> Bool where T: Comparable {
	guard let lhs = lhs, let rhs = rhs else {
        if rhs == nil {
            return false
        }
		return true
	}

	return lhs < rhs
}

public func ?<= <T>(lhs: T?, rhs: T?) -> Bool where T: Comparable {
	guard let lhs = lhs, let rhs = rhs else {
		if rhs == nil {
			return false
		}
		return true
	}

	return lhs <= rhs
}

//swiftlint:disable:next static_operator
public func ?+ <T>(lhs: T, rhs: T?) -> T where T: AdditiveArithmetic {
	guard let rhs = rhs else {
		return lhs
	}
	return lhs + rhs
}

//swiftlint:disable:next static_operator
public func ?+ <T, U>(lhs: T, rhs: T?) -> T where T: RangeReplaceableCollection, T.SubSequence == U {
	guard let rhs = rhs else {
		return lhs
	}
	return lhs + rhs
}

/**
 Nil healing attempt assignment operator.
 If lefthand operand is nil, then it is assigned with righthand operand.
 Righthand operand may also be nil.
 */
public func ??= <T>(lhs: inout T?, rhs: T?) {
	if lhs == nil, let rhs = rhs {
		lhs = rhs
	}
}

public func |== <T: Comparable>(lhs: T, rhs: [T]) -> Bool {
	rhs.first{ $0 == lhs } != nil
}

public protocol UnwrapDefaultable {}
extension Int: UnwrapDefaultable {}
extension Float: UnwrapDefaultable {}
extension Double: UnwrapDefaultable {}
extension Bool: UnwrapDefaultable {}
extension String: UnwrapDefaultable {}

public protocol AnyTypeOfArray: UnwrapDefaultable {}
extension Array: AnyTypeOfArray {}
extension NSArray: AnyTypeOfArray {}
extension Set: AnyTypeOfArray {}
extension NSSet: AnyTypeOfArray {}

public protocol AnyTypeOfDictionary: UnwrapDefaultable {}
extension Dictionary: AnyTypeOfDictionary {}
extension NSDictionary: AnyTypeOfDictionary {}

public postfix func ^ <T: UnwrapDefaultable>(operand: T?) -> T {
	switch operand {
		case .some(let value):
			return value
		case .none:
        // FIXME: Refactor so force-casting is not needed
        // swiftlint:disable force_cast
			if T.self == String.self {
				return "" as! T
			}

			if T.self == Bool.self {
				return false as! T
			}

			if [Int.self, Double.self, Float.self].contains(where: { $0 == T.self }) {
				return 0 as! T
			}

			if T.self is AnyTypeOfArray.Type {
				return [] as! T
			}

			if T.self is AnyTypeOfDictionary.Type {
				return [:] as! T
			}
        // swiftlint:enable force_cast

			fatalError("Operator ^ is applicable only for selected primitives and arrays/dicts")
	}
}

extension Double {
	static let nilCoordinate = Self.init(Int.max)
}
