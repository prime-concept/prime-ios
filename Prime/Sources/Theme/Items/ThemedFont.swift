import UIKit

typealias ThemedFont = ThemedItem<UIFont>

extension ThemeObjcKeys {
	fileprivate static var fontWeight = "fontWeight"
	fileprivate static var fontItalic = "fontItalic"
	fileprivate static var fontFileName = "fontFileName"
	fileprivate static var fontLineHeightMultiplier = "fontLineHeightMultiplier"
}

extension ThemedItem where ElementType == UIFont {
	func with(
		id: String? = nil,
		size: CGFloat? = nil,
		weight: UIFont.Weight? = nil,
		italic: Bool? = nil,
		lineHeightMultiplier: CGFloat = 1
	) -> ThemedFont {
		let weight = weight ?? self.weight
		let italic = italic ?? self.italic

		let decorator = self.addDecorator { [weak self] font in
			guard let self = self else {
				return font
			}

			let size = size ?? font.pointSize

			let fileName = Self.fileName(with: self.fontFileName, weight: weight, isItalic: italic)
			let font = UIFont(name: fileName, size: size)
			return font ?? UIFont.systemFont(ofSize: size)
		}

		if id != nil { decorator.id = id }
		
		decorator.lineHeightMultiplier = lineHeightMultiplier

		return decorator
	}

	var lineHeight: CGFloat {
		self.rawValue.pointSize * self.lineHeightMultiplier
	}
}

extension ThemedItem where ElementType == UIFont {
	convenience init(fontFileName: String) {
		self.init(UIFont(name: fontFileName, size: 16) ?? UIFont.systemFont(ofSize: 16))
		self.fontFileName = fontFileName
	}

	convenience init(fontFileName: String, id: String) {
		let font = UIFont(name: fontFileName, size: 16) ?? UIFont.systemFont(ofSize: 16)
		self.init(font, id: id)
	}

	private static func fileExists(_ name: String) -> Bool {
		let exists = Bundle(for: Self.self).path(forResource: name, ofType: "ttf") != nil
		return exists
	}

	static func fileName(with name: String, weight: UIFont.Weight, isItalic: Bool = false) -> String {
		switch weight {
			case UIFont.Weight.ultraLight:
				let name = name.ultraLight.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			case UIFont.Weight.light:
				let name = name.light.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			case  UIFont.Weight.thin:
				let name = name.thin.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			case  UIFont.Weight.medium:
				let name = name.medium.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			case UIFont.Weight.semibold:
				let name = name.semibold.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			case UIFont.Weight.bold:
				let name = name.bold.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			case  UIFont.Weight.heavy:
				let name = name.heavy.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			case  UIFont.Weight.black:
				let name = name.black.italic(isItalic)
				guard self.fileExists(name) else {
					fallthrough
				}
				return name
			default:
				let name = name.regular.italic(isItalic)
				guard self.fileExists(name) else {
					return name.regular
				}
				return name
		}
	}

	private(set) var italic: Bool {
		get {
			let result: Bool? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.fontItalic)

			return result ?? self.fontFileName.hasSuffix("-Italic")
		}
		set {
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.fontItalic
			)
		}
	}

	private(set) var weight: UIFont.Weight {
		get {
			let result: UIFont.Weight? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.fontWeight)

			return result ?? .regular
		}
		set {
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.fontWeight
			)
		}
	}

	private(set) var fontFileName: String {
		get {
			let result: String? =
			ObjcAssociatedProperty.get(from: self, for: &ThemeObjcKeys.fontFileName)

			return result ?? self.rawValue.fontName
		}
		set {
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.fontFileName
			)
		}
	}

	var lineHeightMultiplier: CGFloat {
		get {
			ObjcAssociatedProperty.get(
				from: self,
				for: &ThemeObjcKeys.fontLineHeightMultiplier
			) ?? 1.0
		}

		set {
			ObjcAssociatedProperty.set(
				newValue,
				to: self,
				for: &ThemeObjcKeys.fontLineHeightMultiplier
			)
		}
	}
}

extension String {
	var themedFont: ThemedFont {
		ThemedFont(fontFileName: self)
	}

	func themedFont(_ id: String) -> ThemedFont {
		ThemedFont(fontFileName: self, id: id)
	}

	//regular
	fileprivate var regular: String { self }

	//lights
	fileprivate var ultraLight: String { self + "-UltraLight" }
	fileprivate var light: String { self + "-Light" }
	fileprivate var thin: String { self + "-Thin" }

	//mediums
	fileprivate var medium: String { self + "-Medium" }
	fileprivate var semibold: String { self + "-Semibold" }

	//bolds
	fileprivate var bold: String { self + "-Bold" }
	fileprivate var heavy: String { self + "-Heavy" }
	fileprivate var black: String { self + "-Black" }

	fileprivate func italic(_ isItalic: Bool) -> String {
		self + (isItalic ? "-Italic" : "")
	}
}

extension UIFont.Weight {
	var string: String {
		switch self {
			case .ultraLight:
				return "ultraLight"
			case .thin:
				return "thin"
			case .light:
				return "light"
			case .regular:
				return "regular"
			case .medium:
				return "medium"
			case .semibold:
				return "semibold"
			case .bold:
				return "bold"
			case .heavy:
				return "heavy"
			case .black:
				return "black"
			default:
				return "UNKNOWN WEIGHT"
		}
	}
}
