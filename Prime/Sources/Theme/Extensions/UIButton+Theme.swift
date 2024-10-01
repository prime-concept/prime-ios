import UIKit

extension ThemeObjcKeys {
	static var titleColorNormal = "titleColorNormal"
	static var titleColorNormalDeallocator = "titleColorNormalDeallocator"

	static var titleColorHighlighted = "titleColorHighlighted"
	static var titleColorHighlightedDeallocator = "titleColorHighlightedDeallocator"

	static var titleColorDisabled = "titleColorDisabled"
	static var titleColorDisabledDeallocator = "titleColorDisabledDeallocator"

	static var titleColorSelected = "titleColorSelected"
	static var titleColorSelectedDeallocator = "titleColorSelectedDeallocator"

	static var backgroundColorNormal = "backgroundColorNormal"
	static var backgroundColorNormalDeallocator = "backgroundColorNormalDeallocator"

	static var backgroundColorHighlighted = "backgroundColorHighlighted"
	static var backgroundColorHighlightedDeallocator = "backgroundColorHighlightedDeallocator"

	static var backgroundColorDisabled = "backgroundColorDisabled"
	static var backgroundColorDisabledDeallocator = "backgroundColorDisabledDeallocator"

	static var backgroundColorSelected = "backgroundColorSelected"
	static var backgroundColorSelectedDeallocator = "backgroundColorSelectedDeallocator"

	static var attributedTitleNormal = "attributedTitleNormal"
	static var attributedTitleNormalDeallocator = "attributedTitleNormalDeallocator"

	static var attributedTitleHighlighted = "attributedTitleHighlighted"
	static var attributedTitleHighlightedDeallocator = "attributedTitleHighlightedDeallocator"

	static var attributedTitleDisabled = "attributedTitleDisabled"
	static var attributedTitleDisabledDeallocator = "attributedTitleDisabledDeallocator"

	static var attributedTitleSelected = "attributedTitleSelected"
	static var attributedTitleSelectedDeallocator = "attributedTitleSelectedDeallocator"

	static func titleColorKeys(for state: UIControl.State) -> (UnsafeRawPointer, UnsafeRawPointer)? {
		switch state {
			case .normal:
				return (UnsafeRawPointer(&titleColorNormal), UnsafeRawPointer(&titleColorNormalDeallocator))
			case .highlighted:
				return (UnsafeRawPointer(&titleColorHighlighted), UnsafeRawPointer(&titleColorHighlightedDeallocator))
			case .disabled:
				return (UnsafeRawPointer(&titleColorDisabled), UnsafeRawPointer(&titleColorDisabledDeallocator))
			case .selected:
				return (UnsafeRawPointer(&titleColorSelected), UnsafeRawPointer(&titleColorSelectedDeallocator))
			default:
				return nil
		}
	}

	static func backgroundColorKeys(for state: UIControl.State) -> (UnsafeRawPointer, UnsafeRawPointer)? {
		switch state {
			case .normal:
				return (UnsafeRawPointer(&backgroundColorNormal), UnsafeRawPointer(&backgroundColorNormalDeallocator))
			case .highlighted:
				return (UnsafeRawPointer(&backgroundColorHighlighted), UnsafeRawPointer(&backgroundColorHighlightedDeallocator))
			case .disabled:
				return (UnsafeRawPointer(&backgroundColorDisabled), UnsafeRawPointer(&backgroundColorDisabledDeallocator))
			case .selected:
				return (UnsafeRawPointer(&backgroundColorSelected), UnsafeRawPointer(&backgroundColorSelectedDeallocator))
			default:
				return nil
		}
	}

	static func attributedTitleKeys(for state: UIControl.State) -> (UnsafeRawPointer, UnsafeRawPointer)? {
		switch state {
			case .normal:
				return (UnsafeRawPointer(&attributedTitleNormal), UnsafeRawPointer(&attributedTitleNormalDeallocator))
			case .highlighted:
				return (UnsafeRawPointer(&attributedTitleHighlighted), UnsafeRawPointer(&attributedTitleHighlightedDeallocator))
			case .disabled:
				return (UnsafeRawPointer(&attributedTitleDisabled), UnsafeRawPointer(&attributedTitleDisabledDeallocator))
			case .selected:
				return (UnsafeRawPointer(&attributedTitleSelected), UnsafeRawPointer(&attributedTitleSelectedDeallocator))
			default:
				return nil
		}
	}
}

extension UIButton {
	func setTitleColor(_ color: ThemedColor?, for state: UIControl.State) {
		self.setTitleColor(color?.rawValue, for: state)

		guard let keys = ThemeObjcKeys.titleColorKeys(for: state) else {
			return
		}

		ObjcAssociatedProperty.set(
			color,
			to: self,
			for: keys.0
		)

		let token = color?.subscribe { [weak self] color in
			self?.setTitleColor(color, for: state)
		}

		guard let token = token else {
			ObjcAssociatedProperty.remove(keys.1, from: self)
			return
		}

		let deallocator = Deallocator { [weak color] in
			color?.unsubscribe(token)
		}

		ObjcAssociatedProperty.set(
			deallocator,
			to: self,
			for: keys.1
		)
	}

	func setBackgroundColor(_ color: ThemedColor?, for state: UIControl.State) {
		self.setBackgroundColor(color?.rawValue, for: state)

		guard let keys = ThemeObjcKeys.titleColorKeys(for: state) else {
			return
		}

		ObjcAssociatedProperty.set(
			color,
			to: self,
			for: keys.0
		)

		let token = color?.subscribe { [weak self] color in
			self?.setBackgroundColor(color, for: state)
		}

		guard let token = token else {
			ObjcAssociatedProperty.remove(keys.1, from: self)
			return
		}

		let deallocator = Deallocator { [weak color] in
			color?.unsubscribe(token)
		}

		ObjcAssociatedProperty.set(
			deallocator,
			to: self,
			for: keys.1
		)
	}
}

extension UIButton {
	static func adaptThemedAttributedTitles() {
		swizzle(
			Self.self,
			#selector(self.setAttributedTitle(_:for:)),
			#selector(Self.swizzled_setAttributedTitle(_:for:))
		)
	}

	@objc
	dynamic private func swizzled_setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
		self.swizzled_setAttributedTitle(title, for: state)

		guard let keys = ThemeObjcKeys.attributedTitleKeys(for: state) else {
			return
		}

		let deallocatorKey = keys.1

		var deallocators: [Deallocator] = ObjcAssociatedProperty.get(
			from: self,
			for: deallocatorKey
		) ?? []

		deallocators.forEach {  $0.closure() }

		ObjcAssociatedProperty.remove(deallocatorKey, from: self)

		guard let attributedText = title, attributedText.length > 0 else {
			return
		}

		var paletteElements = [NSObject]()

		attributedText.enumerateAttributes { attributes, range, _ in
			let themableAttributes = [
				attributes[.backgroundColorThemed],
				attributes[.foregroundColorThemed],
				attributes[.fontThemed]
			].compactMap{ $0 }

			func onThemedItemChanged() {
				let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
				let attributesRanged = mutableAttributedText.attributesRanged

				attributesRanged.forEach { pair in
					var attributes = pair.0
					let range = pair.1

					if let backgroundColorThemed = attributes[.backgroundColorThemed] as? ThemedColor {
						attributes[.backgroundColor] = backgroundColorThemed.rawValue
					}

					if let foregroundColorThemed = attributes[.foregroundColorThemed] as? ThemedColor {
						attributes[.foregroundColor] = foregroundColorThemed.rawValue
					}

					if let fontThemed = attributes[.fontThemed] as? ThemedFont {
						attributes[.font] = fontThemed.rawValue
					}

					mutableAttributedText.setAttributes(attributes, range: range)
				}

				self.swizzled_setAttributedTitle(mutableAttributedText, for: state)
			}

			func subscribe<T: ThemedItemProtocol>(to paletteElement: ThemedItem<T>?) {
				guard let paletteElement = paletteElement else {
					return
				}

				if paletteElements.contains(where: { $0 === paletteElement }) {
					return
				}

				paletteElements.append(paletteElement)

				let token = paletteElement.subscribe { _ in
					onThemedItemChanged()
				}

				let deallocator = Deallocator {
					paletteElement.unsubscribe(token)
				}

				deallocators.append(deallocator)
			}

			themableAttributes.forEach {
				subscribe(to: $0 as? ThemedColor)
				subscribe(to: $0 as? ThemedFont)
			}
		}

		ObjcAssociatedProperty.set(
			deallocators,
			to: self,
			for: deallocatorKey
		)
	}
}
