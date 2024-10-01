import Alamofire
import Foundation
import PromiseKit

protocol ProfileEndpointProtocol: CachingEnpointProtocol {
    func getProfile() -> EndpointResponse<Profile>
	func deleteProfile() -> EndpointResponse<EmptyResponse>
    func update(with profile: Profile) -> EndpointResponse<EmptyResponse>
    func getExpenses(date: String) -> EndpointResponse<Transactions>
}

final class ProfileEndpoint: PrimeEndpoint, ProfileEndpointProtocol {
    private static let profileEndpoint = "/me"
    private let authService: LocalAuthServiceProtocol

	// Оставляем shared, это безопасно, тк тут нет стейта зависимого от сессии юзера
	static let shared = ProfileEndpoint(authService: LocalAuthService.shared)

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

    func getProfile() -> EndpointResponse<Profile> {
        return self.retrieve(endpoint: Self.profileEndpoint)
    }

	func deleteProfile() -> EndpointResponse<EmptyResponse> {
		return self.remove(endpoint: Self.profileEndpoint)
	}

    func update(with profile: Profile) -> EndpointResponse<EmptyResponse> {
        guard let data = try? JSONEncoder().encode(profile),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return (Promise<EmptyResponse>(error: Error(.invalidDataEncoding)), { })
        }

        return self.update(
            endpoint: Self.profileEndpoint,
            parameters: dict
        )
    }

    func getExpenses(date: String) -> EndpointResponse<Transactions> {
        return self.retrieve(endpoint: "/me/balance/\(date)")
    }
}
