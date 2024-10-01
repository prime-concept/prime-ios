import Alamofire
import Foundation
import PromiseKit

struct Services: Codable {
	struct Service: Codable {
		let id: Int?
		let name: String?
		let description: String?
		let url: String?
		let icon: String?
	}

	let data: [Service]?
}

protocol ServicesEndpointProtocol: CachingEnpointProtocol {
	var latestServices: Services? { get }
	func getServices() -> EndpointResponse<Services>
}

final class ServicesEndpoint: PrimeEndpoint, ServicesEndpointProtocol {
	private let authService: LocalAuthServiceProtocol

	static func makeInstance() -> ServicesEndpoint {
		ServicesEndpoint(authService: LocalAuthService.shared)
	}

	init(authService: LocalAuthServiceProtocol) {
		self.authService = authService
		super.init()
	}

	required init(
		basePath: String,
		requestAdapter: RequestAdapter? = nil,
		requestRetrier: RequestRetrier? = nil
	) {
		self.authService = LocalAuthService.shared
		super.init(
			basePath: basePath,
			requestAdapter: requestAdapter,
			requestRetrier: requestRetrier
		)
	}

	private(set) var latestServices: Services?
	private static let datetimeCharactersSet = CharacterSet(charactersIn: "1234567890T-")

	func getServices() -> EndpointResponse<Services> {
		let promise: Promise<Services> = Promise { seal in
			LocationService.shared.fetchLocation { [weak self] result in
				guard let self = self else {
					seal.reject(NSError())
					return false
				}
				let date = Date().string("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
					.addingPercentEncoding(withAllowedCharacters: Self.datetimeCharactersSet) ?? ""
				var endpoint = "/me/services?datetime=\(date)"
				if case .success(let location) = result {
					endpoint.append("&latitude=\(location.latitude)&longitude=\(location.longitude)")
				}

				DispatchQueue.global().promise {
					self.retrieve(endpoint: endpoint).promise
				}.done { (services: Services) in
					self.latestServices = services
					seal.fulfill(services)
				}.catch { error in
					AnalyticsReportingService
						.shared.log(
							name: "[ERROR] \(Swift.type(of: self)) getServices failed",
							parameters: error.asDictionary
						)

					seal.reject(error)
				}

				return false
			}
		}

		return (promise, {})
	}
}
