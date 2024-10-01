import UIKit
import CommonCrypto
import Alamofire

protocol TinkoffLoginEndpointProtocol {
	func fetchOauthToken(code: String, verifier: String) -> EndpointResponse<AccessToken>
}

class TinkoffLoginEndpoint: Endpoint, PrimeEndpointProtocol {
	static let shared = TinkoffLoginEndpoint()
	
	static let endpoint = "\(Config.tinkoffAuthEndpoit)"

	func fetchOauthToken(code: String, verifier: String) -> EndpointResponse<AccessToken> {
		let params = [
			"code": code,
			"code_verifier": verifier,
			"grant_type": "authorization_code",
			"client_id": Config.clientID
		]
		
		let response = self.create(endpoint: "/token", parameters: params, headers: self.authHeaders) as EndpointResponse<AccessToken>
		return response
	}

	func refreshOauthToken(refreshToken: String) -> EndpointResponse<AccessToken> {
		let params = [
			"refresh_token": refreshToken,
			"grant_type": "refresh_token",
			"client_id": Config.clientID
		]

		var headers = self.authHeaders
		headers["Content-Type"] = "application/x-www-form-urlencoded"

		let response = self.create(endpoint: "/token", parameters: params, headers: headers) as EndpointResponse<AccessToken>
		return response
	}

	override var needsTokenToExecuteRequests: Bool {
		false
	}

	override var usesResponseCache: Bool {
		false
	}

	init() {
		super.init(
			basePath: Self.endpoint,
			requestAdapter: PrimeRequestAdapter(authService: LocalAuthService()),
			requestRetrier: TokenExpirationRetrier.shared
		)
	}

	required init(
		basePath: String,
		requestAdapter: RequestAdapter? = nil,
		requestRetrier: RequestRetrier? = nil
	) {
		super.init(
			basePath: basePath,
			requestAdapter: requestAdapter,
			requestRetrier: requestRetrier
		)
	}
}
