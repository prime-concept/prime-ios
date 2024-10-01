import Foundation

extension Notification.Name {
	static let tinkoffAuthSuccess = Notification.Name("tinkoffAuthSuccess")
	static let tinkoffAuthFailed = Notification.Name("tinkoffAuthFailed")
}

class TinkoffAuthService {
	static let shared = TinkoffAuthService()

	private var codeVerifier: String? = nil

	private var codeChallenge: String = "n/a"

	private let host = Config.tinkoffAuthEndpoit + "/authorize"

	private func makeNewVerifierAndChallenge() {
		let verifier = UUID().uuidString.uppercased()
		let challenge = (try? PKCE.challenge(for: verifier)) ?? ""
		let challengeEncoded = challenge.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)^
		
		self.codeVerifier = verifier
		self.codeChallenge = challengeEncoded
	}

	func makeAuthorizationURL(phone: String) -> URL {
		self.makeNewVerifierAndChallenge()

		let string = self.host
		+ "?client_id=\(Config.clientID)&code_challenge=\(self.codeChallenge)"
		+ "&code_challenge_method=S256&response_type=code"
		+ "&phone=\(phone)"

		return URL(string: string)!
	}
}

extension TinkoffAuthService: DeeplinkServiceDelegate {
	func makeDeeplink(from url: URL) -> DeeplinkService.Deeplink? {
		let urlComponents = URLComponents(string: url.absoluteString)
		let host = urlComponents?.host
		let queryItems = urlComponents?.queryItems

		guard let host, host == "auth", let queryItems, let path = urlComponents?.path else {
			return nil
		}

		if path == "/success" {
			self.handleSuccessAuthDeeplink(from: queryItems)
		} else if path == "/failed" {
			self.handleFailedAuthDeeplink(from: queryItems)
		}

		return nil
	}

	private func handleSuccessAuthDeeplink(from queryItems: [URLQueryItem]) {
		let code = queryItems.first{ $0.name == "code" || $0.name == "token" }?.value
		guard let code else {
			Notification.post(.tinkoffAuthFailed)
			return
		}

		Notification.post(.tinkoffAuthSuccess,
			userInfo: ["code": code, "verifier": self.codeVerifier!]
		)
	}

	private func handleFailedAuthDeeplink(from queryItems: [URLQueryItem]) {
		let errorComponent = queryItems.first{ $0.name == "error" }
		let error = errorComponent?.value ?? ""

		Notification.post(.tinkoffAuthFailed, userInfo: ["error": error])
	}
}
