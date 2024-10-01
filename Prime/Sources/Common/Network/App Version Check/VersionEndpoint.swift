import Foundation
import PromiseKit
import Alamofire

struct VersionResponse: Decodable {
	let clientId: String
	let name: String
	let os: String
	let version: String
	let minSupportedVersion: String
}

protocol VersionEndpointProtocol {
	func retrieve() -> EndpointResponse<VersionResponse>
}

final class VersionEndpoint: PrimeEndpoint, VersionEndpointProtocol {
	private static let versionEndpoint = "/app/version"

	// Оставляем shared, это безопасно, тк тут нет стейта
	static let shared = VersionEndpoint()

	override var notifiesServiceUnreachable: Bool {
		false
	}

	override var needsTokenToExecuteRequests: Bool {
		false
	}

	func retrieve() -> EndpointResponse<VersionResponse> {
		var params = self.paramsWithCredentials
		params["client_id"] = Config.clientID

		return self.retrieve(
			endpoint: Self.versionEndpoint,
			parameters: params
		)
	}
}
