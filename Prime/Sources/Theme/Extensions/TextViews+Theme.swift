import UIKit

extension ThemeObjcKeys {
	static var font = "font"
	static var fontDeallocator = "fontDeallocator"

	static var textColor = "textColor"
	static var textColorDeallocator = "textColorDeallocator"

	static var attributedStringDeallocators = "attributedStringDeallocators"
}

protocol TextThemed: AnyObject {
	var fontThemed: ThemedFont? { get set }
	var textColorThemed: ThemedColor? { get set }
	var _attributedText: NSAttributedString? { get set }
	var attributedTextThemed: NSAttributedString? { get set }
}

extension UILabel: TextThemed {
	var _attributedText: NSAttributedString? {
		get { self.attributedText }
		set { self.attributedText = newValue }
	}
}

extension UITextField: TextThemed {
	var _attributedText: NSAttributedString? {
		get { self.attributedText }
		set { self.attributedText = newValue }
	}
}

extension UITextView: TextThemed {
	var _attributedText: NSAttributedString? {
		get { self.attributedText }
		set { self.attributedText = newValue }
	}
}

extension TextThemed {
	private var _textColor: UIColor? {
		get {
			(self as? UILabel)?.textColor ??
			(self as? UITextField)?.textColor ??
			(self as? UITextView)?.textColor
		}
		set {
			(self as? UILabel)?.textColor = newValue
			(self as? UITextField)?.textColor = newValue
			(self as? UITextView)?.textColor = newValue
		}
	}

	private var _font: UIFont? {
		get {
			(self as? UILabel)?.font ??
			(self as? UITextField)?.font ??
			(self as? UITextView)?.font
		}
		set {
			(self as? UILabel)?.font = newValue
			(self as? UITextField)?.font = newValue
			(self as? UITextView)?.font = newValue
		}
	}

	var textColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.textColor)

			return result
		}
		set {
			self._textColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.textColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?._textColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.textColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.textColorDeallocator
			)
		}
	}

	var fontThemed: ThemedFont? {
		get {
			let result: ThemedFont? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.font)

			return result
		}
		set {
			self._font = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.font
			)

			let token = newValue?.subscribe { [weak self] font in
				self?._font = font
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.fontDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.fontDeallocator
			)
		}
	}

	var attributedTextThemed: NSAttributedString? {
		get {
			self._attributedText
		}

		set {
			if let newValue = newValue, let oldValue = self._attributedText, oldValue.isEqual(to: newValue) {
				return
			}

 			self._attributedText = newValue

			var deallocators: [Deallocator] = ObjcAssociatedProperty.get(
				from: self,
				for: &ThemeObjcKeys.attributedStringDeallocators
			) ?? []

			ObjcAssociatedProperty.remove(&ThemeObjcKeys.attributedStringDeallocators, from: self)

			guard let attributedText = newValue, attributedText.length > 0 else {
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

					   self._attributedText = mutableAttributedText
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
				for: &ThemeObjcKeys.attributedStringDeallocators
			)
		}
	}
}

extension UIRefreshControl {
	static func adaptThemes() {
		swizzle(
			Self.self,
			#selector(setter: self.attributedTitle),
			#selector(Self.swizzled_setAttributedTitle(_:))
		)
	}

	@objc
	dynamic private func swizzled_setAttributedTitle(_ attributedText : NSAttributedString?) {
		self.swizzled_setAttributedTitle(attributedText )

		var deallocators: [Deallocator] = ObjcAssociatedProperty.get(
			from: self,
			for: &ThemeObjcKeys.attributedStringDeallocators
		) ?? []

		ObjcAssociatedProperty.remove(&ThemeObjcKeys.attributedStringDeallocators, from: self)

		guard let attributedText = attributedText, attributedText.length > 0 else {
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

				self.swizzled_setAttributedTitle(mutableAttributedText)
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
			for: &ThemeObjcKeys.attributedStringDeallocators
		)
	}
}

extension NSAttributedString {
	static func adaptThemes() {
		swizzle(
			Self.self,
			#selector(Self.init(string:attributes:)),
			#selector(Self.swizzled_init(string:attributes:))
		)
	}

	@objc
	dynamic private func swizzled_init(string: String, attributes: [NSAttributedString.Key: Any]) -> Self {
		var attributes = attributes
		if let backgroundColorThemed = attributes[.backgroundColor] as? ThemedColor {
			attributes[.backgroundColor] = backgroundColorThemed.rawValue
			attributes[.backgroundColorThemed] = backgroundColorThemed
		}

		if let foregroundColorThemed = attributes[.foregroundColor] as? ThemedColor {
			attributes[.foregroundColor] = foregroundColorThemed.rawValue
			attributes[.foregroundColorThemed] = foregroundColorThemed
		}

		if let fontThemed = attributes[.font] as? ThemedFont {
			attributes[.font] = fontThemed.rawValue
			attributes[.fontThemed] = fontThemed
		}

		let result = self.swizzled_init(string: string, attributes: attributes)
		return result
	}
}


extension UILabel {
	var textThemed: String? {
		get { self.text }

		set {
			guard let text = newValue else {
				self.attributedText = nil
				return
			}

			var textBuilder = text.attributed()

			if let font = self.fontThemed {
				textBuilder = textBuilder.themedFont(font)
			}

			self.attributedText = textBuilder
				.lineBreakMode(self.lineBreakMode)
				.alignment(self.textAlignment)
				.string()

			self.numberOfLines = self.numberOfLines
			self.lineBreakMode = self.lineBreakMode
		}
	}
}
