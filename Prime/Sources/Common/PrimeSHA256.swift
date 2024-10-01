import Foundation
import CommonCrypto

struct PrimeSHA256 {
	static func digest(_ input: NSData) -> NSData {
		let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
		var hash = [UInt8](repeating: 0, count: digestLength)
		CC_SHA256(input.bytes, UInt32(input.length), &hash)
		return NSData(bytes: hash, length: digestLength)
	}

	private static func hexStringFromData(input: NSData) -> String {
		var bytes = [UInt8](repeating: 0, count: input.length)
		input.getBytes(&bytes, length: input.length)

		var hexString = ""
		for byte in bytes {
			hexString += String(format: "%02x", UInt8(byte))
		}

		return hexString
	}
}

extension String {
	var sha256_base64: String {
		let stringData = self.data(using: String.Encoding.utf8) as NSData?
		guard let stringData else {
			return ""
		}

		let data = PrimeSHA256.digest(stringData)
		let string = data.base64EncodedString()
			.replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
			.replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
			.replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
			.trimmingCharacters(in: .whitespaces)

		return string
	}
	
	var sha256_hex: String {
		var result = ""
		if let stringData = self.data(using: String.Encoding.utf8) as NSData? {
			let data = PrimeSHA256.digest(stringData)
			result = hexStringFrom(data: data)
		}
		return result
	}

	private func hexStringFrom(data: NSData) -> String {
		var bytes = [UInt8](repeating: 0, count: data.length)
		data.getBytes(&bytes, length: data.length)

		var hexString = ""
		for byte in bytes {
			hexString += String(format:"%02x", UInt8(byte))
		}

		return hexString
	}
}

extension Dictionary where Key == String {
	var orderedStringRepresentation: String {
		var result = ""
		self.keys.sorted(by: <).forEach { key in
			result.append("\(key)")
			if let value = self[key] {
				if let nestedDictionary = value as? [String: Any] {
					result.append(":\(nestedDictionary.orderedStringRepresentation)")
				} else {
					result.append(":\(value)")
				}
			}
			result.append(";")
		}
		return result
	}
}
