import UIKit

extension CVarArg {
	/// format - printf-style format string
	func string(format: String) -> String {
		NSString(format: format as NSString, self) as String
	}
}

extension String {
	func replacing(regex: String, with replacement: String) -> String {
		self.replacingOccurrences(of: regex, with: replacement, options: .regularExpression)
	}

	func stripping(regex: String) -> String {
		self.replacingOccurrences(of: regex, with: "", options: .regularExpression)
	}

	func first(match regex: String) -> String? {
		if let range = self.range(of: regex, options: .regularExpression) {
			return String(self.prefix(upTo: range.upperBound).suffix(from: range.lowerBound))
		}

		return nil
	}

	func contains(regex: String) -> Bool {
		self.first(match: regex) != nil
	}

	func trim(_ characterSet: CharacterSet) -> String {
		self.trimmingCharacters(in: characterSet)
	}

	func trim() -> String {
		self.trim(.whitespacesAndNewlines)
	}
}

extension String {
	private static let ciContext = CIContext()

	func qrImage(scale: CGFloat) -> UIImage? {
		let data = self.data(using: .utf8)
		guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
			return nil
		}
		qrFilter.setValue(data, forKey: "inputMessage")

		guard let qrImage = qrFilter.outputImage else {
			return nil
		}

		let transform = CGAffineTransform(scaleX: scale, y: scale)
		let scaledQrImage = qrImage.transformed(by: transform)

		let colorInvertFilter = CIFilter(name: "CIColorInvert")
		colorInvertFilter?.setValue(scaledQrImage, forKey: "inputImage")

		let alphaFilter = CIFilter(name: "CIMaskToAlpha")
		alphaFilter?.setValue(colorInvertFilter?.outputImage, forKey: "inputImage")
		guard let outputImage = alphaFilter?.outputImage else {
			return nil
		}

		if let cgImage = Self.ciContext.createCGImage(outputImage, from: outputImage.extent) {
			return UIImage(cgImage: cgImage).withRenderingMode(.alwaysTemplate)
		}

		return nil
	}

	var asQrImage: UIImage? {
		self.qrImage(scale: 3)
	}
}

extension Array where Element == Optional<String> {
	func joined(_ seprator: String) -> String {
		let components = self.compactMap{ $0 }.skip(\.isEmpty)
		return components.joined(separator: seprator)
	}
}
