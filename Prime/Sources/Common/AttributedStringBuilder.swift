import UIKit

extension NSAttributedString.Key {
	static let fontThemed = NSAttributedString.Key("fontThemed")
	static let backgroundColorThemed = NSAttributedString.Key("backgroundColorThemed")
	static let foregroundColorThemed = NSAttributedString.Key("foregroundColorThemed")
}

final class AttributedStringBuilder {
    private let internalString: String
    fileprivate(set) var attributes: [NSAttributedString.Key: Any] = [:]

    private lazy var paragraphStyle: NSMutableParagraphStyle = {
        if let style = self.attributes[.paragraphStyle] as? NSMutableParagraphStyle {
            return style
        }

        let style = NSMutableParagraphStyle()
        self.attributes[.paragraphStyle] = style

        return style
    }()

    init(string: String) {
        self.internalString = string
    }

    func string() -> NSAttributedString {
		let result = NSAttributedString(string: self.internalString, attributes: self.attributes)
		return result
    }

    func mutableString() -> NSMutableAttributedString {
		return NSMutableAttributedString(attributedString: self.string())
    }

    func alignment(_ value: NSTextAlignment) -> Self {
        self.paragraphStyle.alignment = value
        return self
    }

    func backgroundColor(_ value: UIColor) -> Self {
        self.attributes[.backgroundColor] = value
        return self
    }

    func font(_ value: UIFont) -> Self {
        self.attributes[.font] = value
        return self
    }

    func foregroundColor(_ value: UIColor) -> Self {
        self.attributes[.foregroundColor] = value
        return self
    }

    func lineBreakMode(_ value: NSLineBreakMode) -> Self {
        self.paragraphStyle.lineBreakMode = value
        return self
    }

    func lineSpacing(_ value: CGFloat) -> Self {
        self.paragraphStyle.lineSpacing = value
        return self
    }

    func maximumLineHeight(_ value: CGFloat) -> Self {
        self.paragraphStyle.maximumLineHeight = value
        return self
    }

    func minimumLineHeight(_ value: CGFloat) -> Self {
        self.paragraphStyle.minimumLineHeight = value
        return self
    }

    func lineHeight(_ value: CGFloat) -> Self {
        self.minimumLineHeight(value).maximumLineHeight(value)
    }

    func baselineOffset(_ value: CGFloat?) -> Self {
        self.attributes[.baselineOffset] = value
        return self
    }

    func hyperLink(_ value: String) -> Self {
        self.attributes[.link] = value
        return self
    }

	func lineHeightMultiplier(_ value: CGFloat) -> Self {
		self.paragraphStyle.lineHeightMultiple = value
		return self
	}

	subscript(key: NSAttributedString.Key) -> Any? {
		get { self.attributes[key] }
		set { self.attributes[key] = newValue }
	}
}

extension AttributedStringBuilder {
	func themedFont(_ themedFont: ThemedFont) -> Self {
		let size = themedFont.rawValue.pointSize
		let lineHeight = themedFont.lineHeight

		let lineSpacing = Int((lineHeight - size) / 2)

		var spacing: CGFloat? = nil

		if lineSpacing > 0 {
			spacing = CGFloat(lineSpacing)
		}

		return self.font(themedFont)
			.baselineOffset(spacing)
			.lineHeight(lineHeight)
	}

    func primeFont(
        ofSize size: CGFloat,
        weight: UIFont.Weight = .regular,
        lineHeight: CGFloat
    ) -> Self {
        let lineSpacing = Int((lineHeight - size) / 2)

        if lineSpacing > 0 {
			return self
				.font(Palette.shared.primeFont.with(size: size, weight: weight))
                .baselineOffset(CGFloat(lineSpacing))
                .lineHeight(lineHeight)
        }

        return self
			.font(Palette.shared.primeFont.with(size: size, weight: weight))
			.lineHeight(lineHeight)
    }

    func boldFancyFont(
        ofSize size: CGFloat,
        lineHeight: CGFloat
    ) -> Self {
        let lineSpacing = Int((lineHeight - size) / 2)

        if lineSpacing > 0 {
			return self.font(Palette.shared.fancyFont.with(size: size).rawValue)
                .baselineOffset(CGFloat(lineSpacing))
                .lineHeight(lineHeight)
        }

		return self.font(Palette.shared.fancyFont.with(size: size)).lineHeight(lineHeight)
    }
}

extension String {
    func attributed() -> AttributedStringBuilder { AttributedStringBuilder(string: self) }
}

extension NSAttributedString {
    func concatenate(with attributedString: NSAttributedString) -> NSAttributedString {
        let concatedString = NSMutableAttributedString()

        concatedString.append(self)
        concatedString.append(attributedString)

        return concatedString
    }

	static func + (x: NSAttributedString, y: NSAttributedString) -> NSAttributedString { x.concatenate(with: y) }

	static func += (x: inout NSAttributedString, y: NSAttributedString) { x = x + y }
}


extension AttributedStringBuilder {
	func backgroundColor(_ value: ThemedColor) -> Self {
		self.attributes[.backgroundColor] = value.rawValue
		self.attributes[.backgroundColorThemed] = value
		return self
	}

	func font(_ value: ThemedFont) -> Self {
		self.attributes[.font] = value.rawValue
		self.attributes[.fontThemed] = value
		return self
	}

	func foregroundColor(_ value: ThemedColor) -> Self {
		self.attributes[.foregroundColor] = value.rawValue
		self.attributes[.foregroundColorThemed] = value
		return self
	}
}


extension NSAttributedString {
	typealias AttributesEnumerationBlock = (
		[NSAttributedString.Key : Any], NSRange, UnsafeMutablePointer<ObjCBool>
	) -> Void

	typealias RangedAttributes = ([NSAttributedString.Key : Any], NSRange)

	func enumerateAttributes(using block: AttributesEnumerationBlock) {
		if self.length == 0 {
			return
		}

		self.enumerateAttributes(in: NSRange(location: 0, length: self.length), using: block)
	}

	var attributesRanged: [RangedAttributes] {
		var attributes = [RangedAttributes]()
		self.enumerateAttributes { map, range, _ in
			attributes.append((map, range))
		}

		return attributes
	}
}
