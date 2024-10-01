import UIKit

extension ThemeObjcKeys {
	static var onTintColor = "onTintColor"
	static var onTintColorDeallocator = "onTintColorColorDeallocator"

	static var thumbTintColor = "thumbTintColor"
	static var thumbTintColorDeallocator = "thumbTintColorDeallocator"
}

extension UISwitch {
	var onTintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.onTintColor)

			return result
		}
		set {
			self.onTintColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.onTintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.onTintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.onTintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.onTintColorDeallocator
			)
		}
	}

	var thumbTintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.thumbTintColor)

			return result
		}
		set {
			self.thumbTintColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.thumbTintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.thumbTintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.thumbTintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.thumbTintColorDeallocator
			)
		}
	}
}
