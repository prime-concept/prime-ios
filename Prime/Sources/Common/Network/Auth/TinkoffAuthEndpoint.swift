import Foundation
import PromiseKit

extension AuthEndpoint {
	func set(password: String, phone: String) -> EndpointResponse<EmptyResponse> {
		(
			promise: Promise { $0.fulfill(EmptyResponse()) },
			cancellation: {}
		)
	}

	func refreshOauthToken(username: String, code: String) -> EndpointResponse<AccessToken> {
		let token = LocalAuthService.shared.token

		guard let refreshToken = token?.refreshToken else {
			DebugUtils.shared.log(sender: self, "[TOKEN] TINKOFF HAS NO REFRESH_TOKEN, GO TO PHONE INPUT")

			let error = Endpoint.Error(.requestRejected, code: 499, details: "NO_REFRESH_TOKEN")

			let promise = Promise<AccessToken> { $0.reject(error) }
			let response = (promise: promise, cancellation: {})

			return response
		}

		return TinkoffLoginEndpoint.shared.refreshOauthToken(refreshToken: refreshToken)
	}

	func fetchOauthToken(username: String, code: String) -> EndpointResponse<AccessToken> {
		(
			promise: Promise {
				if let token = LocalAuthService.shared.token {
					$0.fulfill(token)
				} else {
					$0.reject(Endpoint.Error(.invalidURL))
				}
			},
			cancellation: {}
		)
	}

	func logout() -> EndpointResponse<LogoutResponse> {
		(
			promise: Promise {
				$0.fulfill(LogoutResponse(result: "SUCCESS", message: "TINKOFF FAKE (CRM-LESS) LOGOUT"))
			},
			cancellation: {}
		)
	}
}

