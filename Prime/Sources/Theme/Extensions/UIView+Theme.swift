import UIKit

extension ThemeObjcKeys {
	static var backgroundColor = "backgroundColor"
	static var backgroundColorDeallocator = "backgroundColorDeallocator"

	static var foregroundColor = "foregroundColor"
	static var foregroundColorDeallocator = "foregroundColorDeallocator"

	static var tintColor = "tintColor"
	static var tintColorDeallocator = "tintColorDeallocator"
}

extension UIView {
	var backgroundColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.backgroundColor)

			return result
		}
		set {
			self.backgroundColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.backgroundColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.backgroundColor = color
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

	var tintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.tintColor)

			return result
		}
		set {
			self.tintColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.tintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.tintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.tintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.tintColorDeallocator
			)
		}
	}
}
