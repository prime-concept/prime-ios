import Foundation
import CommonCrypto

extension Data {
	func aesEncrypt(key: String, iv: String? = nil, options: Int = kCCOptionPKCS7Padding) -> Data? {
		let data = self as NSData

		guard let keyData = key.data(using: String.Encoding.utf8),
			  let cryptData = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) else {
				  return nil
			  }

		let keyLength              = size_t(kCCKeySizeAES128)
		let operation: CCOperation = UInt32(kCCEncrypt)
		let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
		let options:   CCOptions   = UInt32(options)

		var numBytesEncrypted :size_t = 0

		let cryptStatus = CCCrypt(operation,
								  algoritm,
								  options,
								  (keyData as NSData).bytes, keyLength,
								  iv,
								  (data as NSData).bytes, data.count,
								  cryptData.mutableBytes, cryptData.length,
								  &numBytesEncrypted)

		if UInt32(cryptStatus) == UInt32(kCCSuccess) {
			cryptData.length = Int(numBytesEncrypted)
			return cryptData as Data
		}

		return nil
	}

	func aesDecrypt(key: String, iv: String? = nil, options: Int = kCCOptionPKCS7Padding) -> Data? {
		let data = self as NSData
		guard let keyData = key.data(using: String.Encoding.utf8),
			  let cryptData = NSMutableData(length: Int((data.length)) + kCCBlockSizeAES128) else {
				  return nil
			  }

		let keyLength              = size_t(kCCKeySizeAES128)
		let operation: CCOperation = UInt32(kCCDecrypt)
		let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
		let options:   CCOptions   = UInt32(options)

		var numBytesEncrypted :size_t = 0

		let cryptStatus = CCCrypt(operation,
								  algoritm,
								  options,
								  (keyData as NSData).bytes, keyLength,
								  iv,
								  data.bytes, data.length,
								  cryptData.mutableBytes, cryptData.length,
								  &numBytesEncrypted)

		if UInt32(cryptStatus) == UInt32(kCCSuccess) {
			cryptData.length = Int(numBytesEncrypted)
			return cryptData as Data
		}

		return nil
	}
}

extension String {
	var authSignature: String? {
		guard let cData = self.cString(using: .utf8) else {
			return nil
		}

		let keyData = NSData(
			base64Encoded: Config.clientSecret,
			options: .ignoreUnknownCharacters)

		let digestLen = Int(CC_SHA256_DIGEST_LENGTH)
		let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)

		CCHmac(
			CCHmacAlgorithm(kCCHmacAlgSHA256),
			keyData?.bytes,
			keyData?.length ?? 0,
			cData,
			strlen(cData),
			result
		)

		let resultData = NSData(bytes: result, length: digestLen)

		result.deallocate()

		return resultData.base64EncodedString()
	}
}

extension Dictionary where Key == String, Value == Any {
	mutating func insertSignature(generatedFrom seed: String) {
		self["signature"] = seed.authSignature
	}
}
