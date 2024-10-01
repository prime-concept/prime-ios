import UIKit

extension ThemeObjcKeys {
	static var gradientColors = "gradientColors"
	static var gradientColorsDeallocator = "gradientColorsDeallocator"

	static var borderColor = "borderColor"
	static var borderColorDeallocator = "borderColorDeallocator"

	static var shadowColor = "shadowColor"
	static var shadowColorDeallocator = "shadowColorDeallocator"

	static var strokeColor = "strokeColor"
	static var strokeColorDeallocator = "strokeColorDeallocator"

	static var fillColor = "fillColor"
	static var fillColorDeallocator = "fillColorDeallocator"
}

extension CALayer {
	var backgroundColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.backgroundColor)

			return result
		}
		set {
			self.backgroundColor = newValue?.rawValue.cgColor

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.backgroundColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.backgroundColor = color.cgColor
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.backgroundColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.backgroundColorDeallocator
			)
		}
	}

	var shadowColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.shadowColor)

			return result
		}
		set {
			self.shadowColor = newValue?.rawValue.cgColor

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.shadowColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.shadowColor = color.cgColor
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.shadowColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.shadowColorDeallocator
			)
		}
	}

	var borderColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.borderColor)

			return result
		}
		set {
			self.borderColor = newValue?.rawValue.cgColor

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.borderColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.borderColor = color.cgColor
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.borderColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.borderColorDeallocator
			)
		}
	}
}

extension CAGradientLayer {
	var colorsThemed: [ThemedColor]? {
		get {
			let result: [ThemedColor]? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.gradientColors)

			return result
		}
		set {
			self.colors = newValue?.map(\.rawValue.cgColor)

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.gradientColors
			)

			let tokens = newValue?.map { themedColor in
				themedColor.subscribe { [weak self] _ in
					let themedColors = self?.colorsThemed ?? []
					let cgColors = themedColors.map(\.rawValue.cgColor)
					self?.colors = cgColors
				}
			} ?? []

			let deallocators = tokens.map { token in
				Deallocator { [weak self] in
					self?.colorsThemed?.forEach {
						$0.unsubscribe(token)
					}
				}
			}

			ObjcAssociatedProperty.set(
				deallocators,
				to: self,
				for: &ThemeObjcKeys.gradientColorsDeallocator
			)
		}
	}
}

extension CAShapeLayer {
	var strokeColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.strokeColor)

			return result
		}
		set {
			self.strokeColor = newValue?.rawValue.cgColor

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.strokeColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.strokeColor = color.cgColor
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.strokeColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.strokeColorDeallocator
			)
		}
	}

	var fillColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.fillColor)

			return result
		}
		set {
			self.fillColor = newValue?.rawValue.cgColor

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.fillColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.fillColor = color.cgColor
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.fillColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.fillColorDeallocator
			)
		}
	}
}
