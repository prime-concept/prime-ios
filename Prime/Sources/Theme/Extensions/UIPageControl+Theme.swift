import UIKit

extension ThemeObjcKeys {
	static var currentPageIndicatorTintColor = "currentPageIndicatorTintColor"
	static var currentPageIndicatorTintColorDeallocator = "currentPageIndicatorTintColorDeallocator"

	static var pageIndicatorTintColor = "pageIndicatorTintColor"
	static var pageIndicatorTintColorDeallocator = "pageIndicatorTintColorDeallocator"
}

extension UIPageControl {
	var currentPageIndicatorTintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.currentPageIndicatorTintColor)

			return result
		}
		set {
			self.currentPageIndicatorTintColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.currentPageIndicatorTintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.currentPageIndicatorTintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.currentPageIndicatorTintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.currentPageIndicatorTintColorDeallocator
			)
		}
	}

	var pageIndicatorTintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.pageIndicatorTintColor)

			return result
		}
		set {
			self.pageIndicatorTintColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.pageIndicatorTintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.pageIndicatorTintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.pageIndicatorTintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.pageIndicatorTintColorDeallocator
			)
		}
	}
}
