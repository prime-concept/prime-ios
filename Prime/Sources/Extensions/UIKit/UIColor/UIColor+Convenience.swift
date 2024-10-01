import UIKit

extension UIColor {
    convenience init(hex: Int) {
		if hex <= 0xFFFFFF {
			self.init(
				red: CGFloat((hex & 0xff0000) >> 16) / 255.0,
				green: CGFloat((hex & 0x00ff00) >> 8) / 255.0,
				blue: CGFloat(hex & 0x0000ff) / 255.0,
				alpha: CGFloat(1.0)
			)
			return
		}

        self.init(
            red: CGFloat((hex & 0xff000000) >> 24) / 255.0,
            green: CGFloat((hex & 0x00ff0000) >> 16) / 255.0,
            blue: CGFloat((hex & 0x0000ff00) >> 8) / 255.0,
            alpha: CGFloat(hex & 0x000000ff) / 255.0
        )
    }

    convenience init?(hexString: String) {
		var hexStr = hexString.uppercased()

		if hexString == "CLEAR" {
			self.init(white: 0, alpha: 0)
			return
		}
		
        hexStr = hexStr.replacingOccurrences(of: "[^0-9A-F]", with: "", options: .regularExpression, range: nil)
        if let hexInt = Int(hexStr, radix: 16) {
            self.init(hex: hexInt)
        } else {
            return nil
        }
    }

	var asImage: UIImage? {
		let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
		UIGraphicsBeginImageContext(rect.size)
		let context = UIGraphicsGetCurrentContext()!

		context.setFillColor(self.cgColor)
		context.fill(rect)

		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}
}

extension UIColor {
	func trulyEquals(to other: UIColor?) -> Bool {
		guard let other = other else {
			return false
		}

		var r1: CGFloat = 0
		var g1: CGFloat = 0
		var b1: CGFloat = 0
		var a1: CGFloat = 0
		self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

		var r2: CGFloat = 0
		var g2: CGFloat = 0
		var b2: CGFloat = 0
		var a2: CGFloat = 0
		other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

		return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2
	}
}

extension UIColor {
	var hexString: String? {
		toHexString()
	}

	// MARK: - From UIColor to String
	func toHexString(alpha useAlpha: Bool = false) -> String? {
		guard let components = cgColor.components, components.count >= 3 else {
			return "CLEAR"
		}

		let red = Float(components[safe: 0] ?? 0)
		let green = Float(components[safe: 1] ?? 0)
		let blue = Float(components[safe: 2] ?? 0)
		var alpha = Float(1.0)

		if components.count >= 4 {
			alpha = Float(components[3])
		}

		if useAlpha && alpha != 1 {
			return String(format: "%02lX%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255), lroundf(alpha * 255))
		}

		return String(format: "%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
	}

	var alpha: CGFloat {
		let string = toHexString(alpha: true)
		guard let string = string, string.count > 6 else {
			return 1
		}
		let alpha = String(string.suffix(string.count - 6))
		let alphaFloat = CGFloat(Int(alpha, radix: 16) ?? 0xFF)
		return alphaFloat / CGFloat(0xFF)
	}
}
