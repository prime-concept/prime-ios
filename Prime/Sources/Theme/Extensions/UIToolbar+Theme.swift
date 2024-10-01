import UIKit
import SwiftTryCatchSPM

extension ThemeObjcKeys {
	static var barTintColor = "barTintColor"
	static var barTintColorDeallocator = "barTintColorDeallocator"
}

extension UIToolbar {
	var barTintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.barTintColor)

			return result
		}
		set {
			self.barTintColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.barTintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.barTintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.barTintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.barTintColorDeallocator
			)
		}
	}

	static func makeBarButtonItemsAdaptThemes() {
		swizzle(
			Self.self,
			#selector(Self.setItems(_:animated:)),
			#selector(Self.swizzled_setItems(_:animated:))
		)

//		swizzle(
//			Self.self,
//			#selector(setter: self.items),
//			#selector(Self.swizzled_items(_:))
//		)
	}

	@objc
	dynamic private func swizzled_setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
		self.swizzled_setItems(items, animated: animated)
		Notification.onReceive(.paletteDidChange, uniqueBy: self) { [weak self] _ in
			SwiftTryCatch.tryAndLog {
				self?.swizzled_setItems(self?.items, animated: animated)
			}
		}
	}

	@objc
	dynamic private func swizzled_items(_ items: [UINavigationItem]?) {
		self.swizzled_items(items)
//		Type of expression is ambiguous without more context
//		Чертов свифт! У тебя точно такой же вызов в методе сверху нифига не амбигоус!
//		Notification.onReceive(.paletteDidChange, uniqueBy: self) { [weak self] _ in
//			self?.swizzled_items(self?.items)
//		}
	}
}

extension UINavigationBar {
	var barTintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.barTintColor)

			return result
		}
		set {
			self.barTintColor = newValue?.rawValue
			
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.barTintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.barTintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.barTintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.barTintColorDeallocator
			)
		}
	}

	static func makeBarButtonItemsAdaptThemes() {
		swizzle(
			Self.self,
			#selector(Self.setItems(_:animated:)),
			#selector(Self.swizzled_setItems(_:animated:))
		)

		swizzle(
			Self.self,
			#selector(setter: self.items),
			#selector(Self.swizzled_items(_:))
		)
	}

	@objc
	dynamic private func swizzled_setItems(_ items: [UINavigationItem]?, animated: Bool) {
		self.swizzled_setItems(items, animated: animated)
		Notification.onReceive(.paletteDidChange, uniqueBy: self) { [weak self] _ in
			SwiftTryCatch.tryAndLog {
				self?.swizzled_setItems(self?.items, animated: animated)
			}
		}
	}

	@objc
	dynamic private func swizzled_items(_ items: [UINavigationItem]?) {
		self.swizzled_items(items)
		Notification.onReceive(.paletteDidChange, uniqueBy: self) { [weak self] _ in
			SwiftTryCatch.tryAndLog {
				self?.swizzled_items(self?.items)
			}
		}
	}
}

extension UIBarButtonItem {
	var tintColorThemed: ThemedColor? {
		get {
			let result: ThemedColor? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.barTintColor)

			return result
		}
		set {
			self.tintColor = newValue?.rawValue

			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.barTintColor
			)

			let token = newValue?.subscribe { [weak self] color in
				self?.tintColor = color
			}

			guard let token = token else {
				ObjcAssociatedProperty.remove(&ThemeObjcKeys.barTintColorDeallocator, from: self)
				return
			}

			let deallocator = Deallocator { [weak newValue] in
				newValue?.unsubscribe(token)
			}

			ObjcAssociatedProperty.set(
				deallocator,
				to: self,
				for: &ThemeObjcKeys.barTintColorDeallocator
			)
		}
	}
}

extension SwiftTryCatch {
	static func tryAndLog(_ block: @escaping () -> Void) {
        SwiftTryCatch.try(block, catch: {
            print("\(#function) \($0.description)")
		}, finally: {
			// close resources
		})
	}
}
