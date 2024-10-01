import Foundation
import PromiseKit

extension AuthEndpoint {
	func set(password: String, phone: String) -> EndpointResponse<EmptyResponse> {
		var params = self.paramsWithCredentials
		params["phone"] = phone
		params["password"] = password

		let signatureSeed = "\(self.paramsString)\(phone)\(password)"
		params.insertSignature(generatedFrom: signatureSeed)

		return self.create(endpoint: Self.setPassword, parameters: params)
	}

	func refreshOauthToken(username: String, code: String) -> EndpointResponse<AccessToken> {
		self.fetchOauthToken(username: username, code: code)
	}

	func fetchOauthToken(username: String, code: String) -> EndpointResponse<AccessToken> {
		let params = ["username": username, "password": code, "grant_type": "password", "scope": "private"]
		let response = self.create(endpoint: Self.fetchOauthToken, parameters: params, headers: self.authHeaders) as EndpointResponse<AccessToken>
		return response
	}

	func logout() -> EndpointResponse<LogoutResponse> {
		var headers = [String: String]()
		if let token = LocalAuthService.shared.token?.accessToken {
			headers["Authorization"] = "Bearer \(token)"
		}
		return self.create(endpoint: Self.logout, headers: headers)
	}
}
