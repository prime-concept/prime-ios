import UIKit

extension Notification.Name {
	static let paletteDidChange = Notification.Name("paletteDidChange")
}

private var isBeingUpdated = false

var paletteIsBeingUpdated: Bool {
	isBeingUpdated
}

class Palette: Codable {
	static let shared = Palette()

	private(set) var primeFont = "GothamPro".themedFont("primeFont")
	private(set) var fancyFont = "PlayfairDisplay-Bold".themedFont("fancyFont")

	private(set) var title = "GothamPro".themedFont.with(id: "title", size: 25, weight: .bold, lineHeightMultiplier: 1.2)
	private(set) var title2 = "GothamPro".themedFont.with(id: "title2", size: 20, weight: .bold, lineHeightMultiplier: 1.2)
	private(set) var title3 = "GothamPro".themedFont.with(id: "title3", size: 18, weight: .bold, lineHeightMultiplier: 1.2)
	private(set) var title4 = "GothamPro".themedFont.with(id: "title4", size: 18, weight: .light, lineHeightMultiplier: 1.2)

	private(set) var smallTitle = "GothamPro".themedFont.with(id: "smallTitle", size: 16, weight: .medium, lineHeightMultiplier: 1.25)
	private(set) var smallTitle2 = "GothamPro".themedFont.with(id: "smallTitle2", size: 15, weight: .medium, lineHeightMultiplier: 1.2)

	private(set) var body = "GothamPro".themedFont.with(id: "body", size: 16, weight: .regular, lineHeightMultiplier: 1.25)
	private(set) var body2 = "GothamPro".themedFont.with(id: "body2", size: 15, weight: .regular, lineHeightMultiplier: 1.2)
	private(set) var body3 = "GothamPro".themedFont.with(id: "body3", size: 14, weight: .regular, lineHeightMultiplier: 1.2)
	private(set) var body4 = "GothamPro".themedFont.with(id: "body4", size: 13, weight: .regular, lineHeightMultiplier: 1.2)

	private(set) var subTitle = "GothamPro".themedFont.with(id: "subTitle", size: 14, weight: .medium, lineHeightMultiplier: 1.2)
	private(set) var subTitle2 = "GothamPro".themedFont.with(id: "subTitle2", size: 13, weight: .medium, lineHeightMultiplier: 1.2)

	private(set) var caption = "GothamPro".themedFont.with(id: "caption", size: 12, weight: .medium, lineHeightMultiplier: 1.2)
	private(set) var caption2 = "GothamPro".themedFont.with(id: "caption2", size: 11, weight: .medium, lineHeightMultiplier: 1.2)
	private(set) var caption3 = "GothamPro".themedFont.with(id: "caption3", size: 10, weight: .medium, lineHeightMultiplier: 1.2)

	private(set) var captionReg = "GothamPro".themedFont.with(id: "captionReg", size: 12, weight: .regular, lineHeightMultiplier: 1.2)
	private(set) var caption2Reg = "GothamPro".themedFont.with(id: "caption2Reg", size: 11, weight: .regular, lineHeightMultiplier: 1.2)
	private(set) var caption3Reg = "GothamPro".themedFont.with(id: "caption3Reg", size: 10, weight: .regular, lineHeightMultiplier: 1.2)

	private(set) var titles = 0x000000.themedColor("titles")

	private(set) var darkColor = 0x363636.themedColor("darkColor")
    private(set) var darkLightColor = 0x828082.themedColor("darkLightColor")

    private(set) var secondBlack = 0x121212.themedColor("secondBlack")
	private(set) var mainBlack = 0x382823.themedColor("mainBlack")

	private(set) var draft = 0x4A7554.themedColor("draft")
    private(set) var danger = 0xd0343e.themedColor("danger")
	private(set) var burgundyColor = 0x5a2f23.themedColor("burgundyColor")

	private(set) var attention = 0xFFB900.themedColor("attention")
    private(set) var brandPrimary = 0xC8AD7D.themedColor("brandPrimary")
	private(set) var brandSecondary = 0xAA8E58.themedColor("brandSecondary")
	private(set) var mainButton = 0xAA8E58.themedColor("mainButton")

	private(set) var accentLoader = 0xAC8AD7D.themedColor("accentLoader")
	private(set) var accentAddress = 0xAA8E58.themedColor("accentAddress")

	private(set) var brown = 0x3F1C14.themedColor("brown")
    private(set) var gray0 = 0x202020.themedColor("gray0")

	private(set) var gray1 = 0x808080.themedColor("gray1")
    private(set) var gray2 = 0xc7bca8.themedColor("gray2")
    private(set) var gray3 = 0xdbdbdb.themedColor("gray3")
	private(set) var gray4 = 0xf3f3f3.themedColor("gray4")
    private(set) var gray5 = 0xFFFFFF.themedColor("gray5")
    private(set) var systemLightGray = 0xABABAB.themedColor("systemLightGray")
    private(set) var primaryButton = 0x0C277D.themedColor("primaryButton")

	private(set) var custom_gray6 = 0x6d6e71.themedColor("custom_gray6")
	private(set) var custom_lightGray2 = 0xe9e9e9.themedColor("custom_lightGray2")

	private(set) var shadow1 = 0x382823.themedColor("shadow1")

	private(set) var black = 0x000000.themedColor("black")
	private(set) var clear = ThemedColor(UIColor.clear, id: "clear")

	private(set) var chatReplySwipeBackground = 0x807371.themedColor("chatReplySwipeBackground")
	private(set) var chatAssistantNameColor = 0x4A4A4A.themedColor("chatAssistantNameColor")
}

extension Palette {
	func update(from jsonFile: String) {
		isBeingUpdated = true

		defer {
			isBeingUpdated = false
		}

        guard
            let path = Bundle.main.path(forResource: jsonFile, ofType: ".json"),
            let json = try? String(contentsOfFile: path),
            let data = json.data(using: .utf8),
            let instance = try? JSONDecoder().decode(Palette.self, from: data)
        else { return }

		let selfMirror = Mirror(reflecting: self)
		let newMirror = Mirror(reflecting: instance)

		newMirror.children.forEach { newChild in
			let selfChild = selfMirror.children.first { $0.label == newChild.label }
            if
                let color = selfChild?.value as? ThemedColor,
                let newColor = newChild.value as? ThemedColor
            {
				color.rawValue = newColor.rawValue
				return
			}
            if
                let font = selfChild?.value as? ThemedFont,
                let newFont = newChild.value as? ThemedFont
            {
				font.rawValue = newFont.rawValue
			}
		}
	}

	func themedColor(by id: String?) -> ThemedColor? {
		self.allThemedColors.first{ $0.id == id }
	}

	func themedFont(by id: String?) -> ThemedFont? {
		self.allThemedFonts.first{ $0.id == id }
	}

	var allThemedColors: [ThemedColor] {
		let mirror = Mirror(reflecting: self)
		return mirror.children.compactMap{ $0.value as? ThemedColor }
	}

	var allThemedFonts: [ThemedFont] {
		let mirror = Mirror(reflecting: self)
		let fonts = mirror.children.compactMap{ $0.value as? ThemedFont }
		return fonts
	}

	func randomize() {
		self.allThemedColors.forEach {
			if $0.rawValue.isEqual(UIColor.clear) {
				return
			}
			$0.rawValue = Int.random(in: 0...0xFFFFFF).asUIColor
		}

		self.allThemedFonts.forEach { font in
			font.rawValue = UIFont.random(font.rawValue.pointSize) ?? font.rawValue
		}

        print(try? self.toJSONString())

		Notification.post(.paletteDidChange)
	}

	func restore() {
		self.primeFont.rawValue = "GothamPro".themedFont.rawValue
		self.fancyFont.rawValue = "PlayfairDisplay-Bold".themedFont.rawValue

		self.darkColor.rawValue = 0x363636.asUIColor
		self.darkLightColor.rawValue = 0x828082.asUIColor

		self.secondBlack.rawValue = 0x121212.asUIColor
		self.mainBlack.rawValue = 0x382823.asUIColor

		self.draft.rawValue = 0x4A7554.asUIColor
		self.danger.rawValue = 0xd0343e.asUIColor
		self.burgundyColor.rawValue = 0x5a2f23.asUIColor

		self.attention.rawValue = 0xFFB900.asUIColor
		self.brandPrimary.rawValue = 0x202020.asUIColor
		self.brandSecondary.rawValue = 0x000000.asUIColor

		self.brown.rawValue = 0x3F1C14.asUIColor
		self.gray0.rawValue = 0x202020.asUIColor

		self.gray1.rawValue = 0x808080.asUIColor
		self.gray4.rawValue = 0xf3f3f3.asUIColor
		self.gray3.rawValue = 0xdbdbdb.asUIColor
		self.gray2.rawValue = 0xc7bca8.asUIColor
		self.gray5.rawValue = 0xFFFFFF.asUIColor
        self.systemLightGray.rawValue = 0xABABAB.asUIColor
        self.primaryButton.rawValue = 0x0C277D.asUIColor

		self.custom_gray6.rawValue = 0x6d6e71.asUIColor
		self.custom_lightGray2.rawValue = 0xe9e9e9.asUIColor

		self.shadow1.rawValue = 0x382823.asUIColor

		self.black.rawValue = 0x000000.asUIColor
		self.clear.rawValue = UIColor.clear

		self.chatReplySwipeBackground.rawValue = 0x807371.asUIColor
		self.chatAssistantNameColor.rawValue = 0x4A4A4A.asUIColor

        print(try? self.toJSONString())

		Notification.post(.paletteDidChange)
	}
}

extension UIFont {
	static func random(_ size: CGFloat) -> UIFont? {
		guard let family = UIFont.familyNames.randomElement() else {
			return nil
		}
		guard let fontName = UIFont.fontNames(forFamilyName: family).randomElement() else {
			return nil
		}

		return UIFont(name: fontName, size: size)
	}
}
