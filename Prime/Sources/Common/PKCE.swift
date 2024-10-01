import Foundation
import CryptoKit

precedencegroup ForwardApplication {
	associativity: left
}

infix operator |>: ForwardApplication

// swiftlint:disable:next identifier_name
func |> <A, B>(a: A, f: (A) -> B) -> B {
	f(a)
}

// swiftlint:disable:next identifier_name
func |> <A, B>(a: A, f: (A) throws -> B) throws -> B {
	try f(a)
}

// MARK: - PKCE Code Verifier & Code Challenge

enum PKCEError: Error {
	case failedToGenerateRandomOctets
	case failedToCreateChallengeForVerifier
}

enum PKCE {
	static func base64URLEncode<S>(octets: S) -> String where S: Sequence, UInt8 == S.Element {
		let data = Data(octets)
		return data
			.base64EncodedString() // Regular base64 encoder
			.replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
			.replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
			.replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
			.trimmingCharacters(in: .whitespaces)
	}

	static func challenge(for verifier: String) throws -> String {
		let challenge = verifier // String
			.data(using: .ascii) // Decode back to [UInt8] -> Data?
			.map { CryptoKit.SHA256.hash(data: $0) } // Hash -> SHA256.Digest?
			.map { base64URLEncode(octets: $0) } // base64URLEncode

		if let challenge = challenge {
			return challenge
		} else {
			throw PKCEError.failedToCreateChallengeForVerifier
		}
	}
}


