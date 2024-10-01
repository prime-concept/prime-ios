import UIKit
import PromiseKit

enum ThemeObjcKeys {
	fileprivate static var decoratorDeallocator = "decoratorDeallocator"
}

protocol ThemedItemProtocol: NSObject {}

extension UIColor: ThemedItemProtocol {}
extension UIFont: ThemedItemProtocol {}

class ThemedItem<ElementType: NSObject>: NSObject, Codable {
	var id: String?
	private var subscriptions: [String: (ElementType) -> Void] = [:]

	init(_ rawValue: ElementType, id: String? = nil) {
		self.id = id
		self.rawValue = rawValue
	}

	enum ColorKeys: CodingKey {
		case id
		case hex
		case alpha
	}

	enum FontKeys: CodingKey {
		case id
		case fontName
		case pointSize
		case lineHeightMultiplier
	}

	func encode(to encoder: Encoder) throws {
		if let self = self as? ThemedFont {
			var container = encoder.container(keyedBy: FontKeys.self)
			try? container.encode(self.id, forKey: .id)
			try? container.encode(self.rawValue.fontName, forKey: .fontName)
			try? container.encode(self.rawValue.pointSize, forKey: .pointSize)
			try? container.encode(self.lineHeightMultiplier, forKey: .lineHeightMultiplier)
			return
		}

		if let self = self as? ThemedColor {
			var container = encoder.container(keyedBy: ColorKeys.self)
			try? container.encode(self.id, forKey: .id)
			try? container.encode(self.rawValue.hexString!, forKey: .hex)
			try? container.encode(self.rawValue.alpha, forKey: .alpha)

			return
		}
	}

	required convenience init(from decoder: Decoder) throws {
		self.init(ElementType())

		if let self = self as? ThemedFont {
			let container = try decoder.container(keyedBy: FontKeys.self)

			let id = (try? container.decode(String.self, forKey: .id)) ?? ""
			let themedFont = Palette.shared.themedFont(by: id)

			var lineHeightMultiplier = try? container.decode(CGFloat.self, forKey: .lineHeightMultiplier)
			var fontName = try? container.decode(String.self, forKey: .fontName)
			var pointSize = try? container.decode(CGFloat.self, forKey: .pointSize)

			lineHeightMultiplier = lineHeightMultiplier ?? themedFont?.lineHeightMultiplier
			fontName ??= themedFont?.fontFileName
			pointSize ??= themedFont?.rawValue.pointSize

			self.id = id
			self.lineHeightMultiplier = lineHeightMultiplier ?? 1

			if let fontName = fontName, let pointSize = pointSize {
				let font = UIFont(name: fontName, size: pointSize)!
				self.rawValue = font
			}

			if let themedFont = themedFont {
				let token = themedFont.subscribe { [weak self] font in
					self?.rawValue = font
				}

				self.injectDeallocator {
					themedFont.unsubscribe(token)
				}
			}

			return
		}

		if let self = self as? ThemedColor {
			let container = try decoder.container(keyedBy: ColorKeys.self)

			self.id = try? container.decode(String.self, forKey: .id)
			let hex = (try? container.decode(String.self, forKey: .hex)) ?? "FF0000"
			var alpha = (try? container.decode(CGFloat.self, forKey: .alpha)) ?? 1.0

			if hex.uppercased() == "CLEAR" || id?.uppercased() == "CLEAR" {
				alpha = 0
			}

			self.rawValue = UIColor(hexString: hex)!.withAlphaComponent(alpha)

			guard !paletteIsBeingUpdated, let themedColor = Palette.shared.themedColor(by: self.id) else {
				return
			}

			self.rawValue = themedColor.rawValue.withAlphaComponent(alpha)

			let token = themedColor.subscribe { [weak self] color in
				self?.rawValue = color.withAlphaComponent(alpha)
			}

			self.injectDeallocator {
				themedColor.unsubscribe(token)
			}
		}
	}

	deinit {
		self.subscriptions.removeAll()
	}

	var rawValue: ElementType {
		didSet {
			self.notifySubscribers()
		}
	}

	func subscribe(_ observer: @escaping (ElementType) -> Void) -> String {
		let uuid = UUID().uuidString
		self.subscriptions[uuid] = observer
		return uuid
	}

	func unsubscribe(_ uuid: String) {
		self.subscriptions[uuid] = nil
	}

	fileprivate func notifySubscribers() {
		self.subscriptions.values.forEach { observer in
			observer(self.rawValue)
		}
	}

	/**
	 * Помимо декорирования значений может использоваться и как инъектор произвольного
	 * вью-специфичного кода для выполнения внутри вьюхи.
	 */
	func addDecorator(with handler: @escaping (ElementType) -> ElementType) -> ThemedItem<ElementType> {
		ThemedItemDecorator(source: self, handler: handler)
	}

	@objc
	override func forwardingTarget(for aSelector: Selector!) -> Any? {
		if self.responds(to: aSelector) {
			return self
		}

		if self.rawValue.responds(to: aSelector) {
			return self.rawValue
		}

		return nil
	}

	override var debugDescription: String {
		self.description
	}

	override var description: String {
		let address = Unmanaged.passUnretained(self).toOpaque()
		let result = "\(Self.self)@\(address): \((try? self.toJSONString()) ?? "")"
		return result
	}
}

class ThemedItemDecorator<T: NSObject>: ThemedItem<T> {
	private let source: ThemedItem<T>

	init(source: ThemedItem<T>, handler: @escaping (T) -> T) {
		self.source = source
		super.init(handler(source.rawValue))
		self.id = source.id

		let token = self.source.subscribe { [weak self] element in
			self?.rawValue = handler(element)
		}

		self.injectDeallocator { [weak self] in
			self?.source.unsubscribe(token)
		}

		self.rawValue = handler(self.rawValue)
	}

	required convenience init(from decoder: Decoder) throws {
		let source = try ThemedItem<T>.init(from: decoder)
		let rawValue = T.init()

		self.init(source: source, handler: { _ in rawValue })
	}
}

protocol Themed {
	associatedtype T: NSObject
	var themed: ThemedItem<T> { get }
}

extension NSObject {
	func injectDeallocator(_ block: @escaping () -> Void) {
		let deallocator = Deallocator(block)

		ObjcAssociatedProperty.set(
			deallocator,
			to: self,
			for: &ThemeObjcKeys.decoratorDeallocator
		)
	}
}
