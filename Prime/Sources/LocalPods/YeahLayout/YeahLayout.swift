// Warning! All symbols in this file will be removed. Effective immediately, no new code using them will be accepted.

import UIKit

/*
 Простейшая обертка, упрощающая создание и использование NSLayoutConstraint.
 Позволяет задавать констрейны в одну короткую строку, максимальное похожую
 на предложение на естественном языке, например:

 view.make(.height, .equal, to: .width, of: otherView)
 someView.make(.width, .equal, 100)
 someView.place(under: upperView, +20) // Ниже некоторой вьюхи на 20 пунктов
 someView.place(behind: upperView, +20) // Правее некоторой вьюхи на 20 пунктов

 Можно задавать мультиплаеры и инсеты:
 view.make([.leading, .trailing], .equal, as: [0.5, 0.8], of: otherView, [20, -20])

 Добавляет некоторые упрощения относительно ванильного синтаксиса атрибутов и отношений
 NSLayoutConstraint-ов:

 Отношение .toSuperview для вьюх, уже размещенных на родительской вьюхе:
 someView.make(.width, .equalToSuperview)

 Атрибуты .hEdges, .vEdges, .edges, .edges(except:), представляющие собой массивы атрибутов,
 применяющихся за один вызов метода make.

 Оператор ^ легко задает приоритет констрейнтам:
 view.make(.height, .equal, 44) ^ 750

 Возможность задавать инсеты в виде массива констант [top, left, bottom, right], без утомительного создания UIEdgeInsets.
 Константы используют абсолтные значения, без умственной гимнастики типа
 "ага, это у нас инсет, значит 10 райт это будет на 10 пунктов левее правого края, то есть правый край -10 пунктов".
 В массиве будут только те элементы, которые вы используете в выражении make:
 view.make(.edges(except: .bottom), .equalToSuperview, [10, 10, -10]) // top, left, right. Bottom исключен.
 */

// swiftlint:disable identifier_name

@available(*, deprecated, message: "Use Auto Layout directly")
extension UIView {
	@discardableResult
	public func make(_ attribute: NSLayoutConstraint.Attribute,
					 _ relation: [YeahRelation] = .equal,
					 to v2: Any? = nil,
					 _ constant: CGFloat = 0,
					 priority: UILayoutPriority = .required) -> NSLayoutConstraint
	{
		return make(attribute, relation, to: 1, of: v2, constant, priority: priority)
	}

	@discardableResult
	public func make(_ attributes: [NSLayoutConstraint.Attribute],
					 _ relation: [YeahRelation] = .equal,
					 to v2: Any? = nil,
					 _ constants: [CGFloat] = [],
					 priorities: [UILayoutPriority] = [.required]) -> [NSLayoutConstraint]
	{
		return make(attributes, relation, of: v2, constants, priorities: priorities)
	}

	@discardableResult
	public func make(_ a1: NSLayoutConstraint.Attribute,
					 _ relation: [YeahRelation] = .equal,
					 to a2: NSLayoutConstraint.Attribute = .notAnAttribute,
					 of v2: Any? = nil,
					 _ c: CGFloat = 0,
					 priority: UILayoutPriority = .required)  -> NSLayoutConstraint {
		return make(a1, relation, to: 1, a2, of: v2, c, priority: priority)
	}

	@discardableResult
	public func make(_ a1: NSLayoutConstraint.Attribute,
					 _ relation: [YeahRelation] = .equal,
					 to m: CGFloat,
					 _ a2: NSLayoutConstraint.Attribute = .notAnAttribute,
					 of v2: Any? = nil,
					 _ c: CGFloat = 0,
					 priority: UILayoutPriority = .required) -> NSLayoutConstraint
	{
		self.translatesAutoresizingMaskIntoConstraints = false
		(v2 as? UIView)?.translatesAutoresizingMaskIntoConstraints = false

		var a2 = a2
		if v2 != nil && a2 == .notAnAttribute {
			a2 = a1
		}

		var v2 = v2
		if relation.contains(.toSuperview) {
			if v2 == nil {
				v2 = superview
				if a2 == .notAnAttribute {
					a2 = a1
				}
			} else {
				fatalError("WHEN SPECIFIED .toSuperview RELATION YOU MUST PROVIDE NIL AS A SECOND VIEW!")
			}
		}

		let constraint = NSLayoutConstraint.init(
			item: self,
			attribute: a1,
			relatedBy: relation.nsLayoutRelation,
			toItem: v2,
			attribute: a2,
			multiplier: m,
			constant: c
		)

		constraint.priority = priority

		var secondView: UIView?
		if v2 == nil {
			secondView = nil
		} else if let view = v2 as? UIView {
			secondView = view
		} else if let guide = v2 as? UILayoutGuide {
			secondView = guide.owningView
		} else {
			fatalError("VIEW2 CANNOT BE USED IN LAYOUT CONSTRAINING! \(String(describing: v2))")
		}

		if let ancestor =  self.commonAncestor(with: secondView) {
			ancestor.addConstraint(constraint)
		} else {
			fatalError("VIEW1 AND VIEW2 MUST HAVE A COMMON ANCESTOR!\n\(self)\n\(String(describing: v2))")
		}

		return constraint
	}

	@discardableResult
	public func make(_ attributes: [NSLayoutConstraint.Attribute],
					 _ relation: [YeahRelation] = .equal,
					 to multipliers: [CGFloat] = [],
					 _ correspondingAttributes: [NSLayoutConstraint.Attribute] = [],
					 of v2: Any? = nil,
					 _ constants: [CGFloat] = [],
					 priorities: [UILayoutPriority] = [.required]) -> [NSLayoutConstraint]
	{
		var correspondingAttributes = correspondingAttributes
		if correspondingAttributes.isEmpty {
			correspondingAttributes = attributes
		}

		if attributes.count != correspondingAttributes.count {
			fatalError("ATTRIBUTE SETS MUST CONTAIN SAME AMOUNT OF ELEMENTS!")
		}

		var constants = constants
		if constants.isEmpty {
			constants = .init(repeating: 0, count: attributes.count)
		} else if constants.count == 1 {
			constants = .init(repeating: constants[0], count: attributes.count)
		}

		if attributes.count != constants.count {
			fatalError("CONSTANTS MUST CORRESPOND ITS ATTRIBUTES!")
		}

		var multipliers = multipliers
		if multipliers.isEmpty {
			multipliers = .init(repeating: 1, count: attributes.count)
		} else if multipliers.count == 1 {
			multipliers = .init(repeating: multipliers[0], count: attributes.count)
		}

		var priorities = priorities
		if priorities.isEmpty {
			priorities = .init(repeating: .required, count: attributes.count)
		} else if priorities.count == 1 {
			priorities = .init(repeating: priorities[0], count: attributes.count)
		}

		if attributes.count != multipliers.count {
			fatalError("MULTIPLIERS MUST CORRESPOND ITS ATTRIBUTES!")
		}

		var results = [NSLayoutConstraint]()

		for i in 0..<attributes.count {
			let a1 = attributes[i]
			let a2 = correspondingAttributes[i]
			let m = multipliers[i]
			let c = constants[i]
			let p = priorities[i]

			let constraint = make(a1, relation, to: m, a2, of: v2, c, priority: p)

			results.append(constraint)
		}

		return results
	}
}

@available(*, deprecated, message: "Use Auto Layout directly")
extension UIView {
	@discardableResult
	public func place(behind v2: Any?,
					 by relation: [YeahRelation] = .equal,
					 _ constant: CGFloat = 0,
					 priority: UILayoutPriority = .required) -> NSLayoutConstraint
	{
		return make(.leading, relation, to: .trailing, of: v2, constant, priority: priority)
	}

	@discardableResult
	public func place(under v2: Any?,
					 by relation: [YeahRelation] = .equal,
					 _ constant: CGFloat = 0,
					 priority: UILayoutPriority = .required) -> NSLayoutConstraint
	{
		return make(.top, relation, to: .bottom, of: v2, constant, priority: priority)
	}


	@discardableResult
	public func make(ratio: CGFloat = 0, priority: UILayoutPriority = .required)  -> NSLayoutConstraint {
		return make(.width, .equal, to: ratio, .height, of: self)
	}
}

@available(*, deprecated, message: "Use Auto Layout directly")
extension UIView {
	func make(hug: Int, axis: NSLayoutConstraint.Axis) {
		self.setContentHuggingPriority(hug.layoutPriority, for: axis)
		self.setContentCompressionResistancePriority((1000 - hug).layoutPriority, for: axis)
	}

	func make(resist: Int, axis: NSLayoutConstraint.Axis) {
		self.setContentHuggingPriority((1000 - resist).layoutPriority, for: axis)
		self.setContentCompressionResistancePriority(resist.layoutPriority, for: axis)
	}
}

@available(*, deprecated, message: "Use Auto Layout directly")
public enum YeahRelation: Equatable {
	case equal
	case less
	case greater
	case toSuperview
}

@available(*, deprecated, message: "Use Auto Layout directly")
private extension UIView {
	func commonAncestor(with view: UIView?) -> UIView? {
		guard let view = view else {
			return self
		}
		if self === view {
			return self
		}
		if self.orDescendants(contain: view) {
			return self
		}
		if view.orDescendants(contain: self) {
			return view
		}

		var ancestor: UIView?
		ancestor = self.ancestor(containing: view)
		ancestor = ancestor ?? view.ancestor(containing: self)

		return ancestor
	}

	func orDescendants(except e: UIView? = nil, contain view: UIView) -> Bool {
		for subview in subviews {
			if subview === view {
				return true
			}
			if let e = e, subview === e {
				continue
			}
			if subview.orDescendants(contain: view) {
				return true
			}
		}

		return false
	}

	func ancestor(containing view: UIView) -> UIView? {
		while let superview = superview {
			if superview.orDescendants(except: self, contain: view) {
				return superview
			}
		}

		return nil
	}
}

@available(*, deprecated, message: "Use Auto Layout directly")
@discardableResult
public func + <T>(_ lhs: Array<T>, _ rhs: T) -> Array<T> {
	var lhs = lhs
	lhs.append(rhs)
	return lhs
}

@available(*, deprecated, message: "Use Auto Layout directly")
@discardableResult
public func + <T>(_ lhs: Array<T>, _ rhs: [T]) -> Array<T> {
	var lhs = lhs
	lhs.append(contentsOf: rhs)
	return lhs
}

@available(*, deprecated, message: "Use Auto Layout directly")
public extension Array where Element == NSLayoutConstraint.Attribute {
	static let center: [Element] = [.centerX, .centerY]
	static let edges: [Element] = [.top, .leading, .bottom, .trailing]
	static let size: [Element] = [.width, .height]
	static let hEdges: [Element] = [.leading, .trailing]
	static let vEdges: [Element] = [.top, .bottom]

	static func edges(except e: Element) -> Self {
		assert(edges.contains(e), "YOU CAN EXCLUDE ONLY THESE ATTRIBUTES: \(edges)")
		return edges.filter{ $0 != e }
	}
}

@available(*, deprecated, message: "Use Auto Layout directly")
public extension Array where Element == YeahRelation {
	static let equalToSuperview: [Element] = [.equal, .toSuperview]
	static let lessThanOrEqualToSuperview: [Element] = [.equal, .less, .toSuperview]
	static let greaterThanOrEqualToSuperview: [Element] = [.equal, .greater, .toSuperview]
	static let equal: [Element] = [.equal]
	static let lessThanOrEqual: [Element] = [.equal, .less]
	static let greaterThanOrEqual: [Element] = [.equal, .greater]

	var nsLayoutRelation: NSLayoutConstraint.Relation {
		if self == .equalToSuperview || self == .equal {
			return .equal
		}
		if self == .lessThanOrEqualToSuperview || self == .lessThanOrEqual  {
			return .lessThanOrEqual
		}
		if self == .greaterThanOrEqualToSuperview || self == .greaterThanOrEqual {
			return .greaterThanOrEqual
		}
		fatalError("INCORRECT YEAH RELATION MASK \(self)")
	}
}

@available(*, deprecated, message: "Use Auto Layout directly")
public extension NSLayoutConstraint {
	func remove() -> UIView? {
		var superview: UIView?
		if let view1 = self.firstItem as? UIView,
		   let view2 = self.secondItem as? UIView {
			superview = view1.commonAncestor(with: view2)
		} else {
			superview = (self.firstItem as? UIView) ?? (self.secondItem as? UIView)
		}

		superview?.removeConstraint(self)
		return superview
	}
}

@available(*, deprecated, message: "Use Auto Layout directly")
@discardableResult
public func ^(lhs: NSLayoutConstraint, rhs: Float) -> NSLayoutConstraint {
	lhs ^ UILayoutPriority.init(rhs)
	return lhs
}

@available(*, deprecated, message: "Use Auto Layout directly")
@discardableResult
public func ^(lhs: [NSLayoutConstraint], rhs: Float) -> [NSLayoutConstraint] {
	lhs.forEach { $0 ^ rhs }
	return lhs
}

@available(*, deprecated, message: "Use Auto Layout directly")
@discardableResult
public func ^(lhs: NSLayoutConstraint, rhs: UILayoutPriority) -> NSLayoutConstraint {
	let active = lhs.isActive
	lhs.isActive = false
	let view = lhs.remove()
	lhs.priority = rhs
	lhs.isActive = active
	view?.addConstraint(lhs)
	return lhs
}

@available(*, deprecated, message: "Use Auto Layout directly")
@discardableResult
public func ^(lhs: [NSLayoutConstraint], rhs: UILayoutPriority) -> [NSLayoutConstraint] {
	lhs.forEach { $0 ^ rhs }
	return lhs
}

@available(*, deprecated, message: "Use Auto Layout directly")
extension Int {
	var layoutPriority: UILayoutPriority {
		UILayoutPriority(Float(self))
	}
}

// swiftlint:enable identifier_name
