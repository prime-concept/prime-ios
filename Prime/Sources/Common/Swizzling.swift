import UIKit

func swizzle(_ clazz: AnyClass, _ original: Selector, _ swizzled: Selector) {
	let originalMethod = class_getInstanceMethod(clazz, original)
	let swizzledMethod = class_getInstanceMethod(clazz, swizzled)
	if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
		method_exchangeImplementations(originalMethod, swizzledMethod)
	}
}
