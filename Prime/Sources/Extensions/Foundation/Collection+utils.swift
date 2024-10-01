import Foundation

extension Array {
	func skip(_ evaluation: (Element) -> Bool) -> [Element] {
		filter { !evaluation($0) }
	}

	func deepMap<T>(_ mapper: (Element) -> T) -> [T] {
		var result = [T]()
		self.forEach {
			if let subArray = $0 as? [Element] {
				result.append(contentsOf: subArray.deepMap(mapper))
			} else {
				result.append(mapper($0))
			}
		}
		return result
	}

	/**
	 Разбивает массив на массив подмассивов длиной length.
	 [1, 2, 3, 4, 5].split(by: 2) -> [[1, 2], [3, 4], [5]]
	 */
	func split(by length: Int) -> [Self] {
		var result = [[Element]]()
		var accumulator = [Element]()

		let length = (length < 1) ? 1 : length

		for i in 0..<self.count {
			let element = self[i]
			accumulator.append(element)
			if accumulator.count == length {
				result.append(accumulator)
				accumulator.removeAll()
			}
		}

		if !accumulator.isEmpty {
			result.append(accumulator)
		}
		
		return result
	}
}

extension Array where Element: Comparable {
	mutating func remove(element: Element) {
		self = self.filter { $0 != element}
	}
}

extension Array {
	func unique(by comparator: (Element, Element) -> Bool) -> Self {
		var result: Self = []

		self.forEach { item in
			let uniqueItem = result.first { comparator($0, item) }
			if uniqueItem != nil {
				return
			}
			result.append(item)
		}

		return result
	}

	func unique<V>(by keyPath: KeyPath<Element, V>) -> Self where V: Equatable {
		var result: Self = []

		forEach { element in
			let existentElement = result.first {
				let old = $0[keyPath: keyPath]
				let new = element[keyPath: keyPath]
				return old == new
			}

			if existentElement == nil {
				result.append(element)
			}
		}
		return result
	}

	func unique<V>(by keyPath: KeyPath<Element, V>, reversedSearch: Bool = false) -> Self where V: Equatable & Hashable {
		var result: Self = []
		var takenElements = Set<V>()

		let array = reversedSearch ? Array(self.reversed()) : self

		array.forEach { element in
			let new = element[keyPath: keyPath]

			if takenElements.contains(new) {
				return
			}

			result.append(element)
			takenElements.insert(new)
		}
		return result
	}

	mutating func uniquify<V>(by keyPath: KeyPath<Element, V>) where V: Equatable {
		self = self.unique(by: keyPath)
	}
}
