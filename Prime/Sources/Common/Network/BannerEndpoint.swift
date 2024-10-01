import Foundation
import PromiseKit
import Alamofire

struct Banner: Codable {
	struct Image: Codable {
		let image: String
		let avg: String?
	}

	let id: String
	let images: [Image]
	let link: String
	let category: String
}

struct BannerResponse: Codable {
	let items: [Banner]
}

protocol BannerEndpointProtocol {
	func retrieve() -> EndpointResponse<BannerResponse>
}

final class BannerEndpoint: Endpoint, PrimeEndpointProtocol, BannerEndpointProtocol {
	// Оставляем shared, это безопасно, тк тут нет стейта
	static let shared = BannerEndpoint()

	convenience init() {
		self.init(
			basePath: Config.ptEndpoint,
			requestAdapter: PrimeRequestAdapter(authService: LocalAuthService()),
			requestRetrier: TokenExpirationRetrier.shared
		)
	}

	func retrieve() -> EndpointResponse<BannerResponse> {
		var headers = HTTPHeaders()

		headers["accept"] = "/"
		headers["content-type"] = "application/vnd.api+json"
		headers["x-app-token"] = Config.ptToken
		headers["accept-language"] = "ru-RU;q=1.0, en-US;q=0.9"
		headers["pragma"] = "no-cache"
		headers["cache-control"] = "no-cache"

		return self.retrieve(endpoint: "/v1/screens/banner?filter[application]=\(Config.bannersAppID)", headers: headers)
	}
}
