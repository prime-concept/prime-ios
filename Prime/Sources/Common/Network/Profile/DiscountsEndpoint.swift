import Alamofire
import Foundation
import PromiseKit

protocol DiscountsEndpointProtocol {
    func getDiscountCards() -> EndpointResponse<DiscountsResponse>
    func getDiscountCardTypes() -> EndpointResponse<DiscountTypeResponse>
    func getDiscountCardInfo(with id: Int) -> EndpointResponse<Discount>
    func removeCard(with id: Int) -> EndpointResponse<EmptyResponse>
    func create(discount: Discount) -> EndpointResponse<Discount>
    func update(id: Int, discount: Discount) -> EndpointResponse<Discount>
}

final class DiscountsEndpoint: PrimeEndpoint, DiscountsEndpointProtocol {
    private static let getDiscountCardsEndpoint = "/me/discounts"
    private let authService: LocalAuthServiceProtocol

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

    func getDiscountCards() -> EndpointResponse<DiscountsResponse> {
        return self.retrieve(endpoint: Self.getDiscountCardsEndpoint)
    }

    func getDiscountCardTypes() -> EndpointResponse<DiscountTypeResponse> {
        return self.retrieve(endpoint: "/dict/discounts")
    }


    func removeCard(with id: Int) -> EndpointResponse<EmptyResponse> {
        return self.remove(endpoint: "/me/discounts/\(id)")
    }

    func getDiscountCardInfo(with id: Int) -> EndpointResponse<Discount> {
        return self.retrieve(endpoint: "/dict/discounts/\(id)")
    }

    func create(discount: Discount) -> EndpointResponse<Discount> {
        guard let data = try? JSONEncoder().encode(discount),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return (Promise<Discount>(error: Error(.requestRejected, details: "invalidDiscountEncode")), { })
        }

        return self.create(
            endpoint: "/me/discounts",
            parameters: dict,
            encoding: JSONEncoding.default
        )
    }

    func update(id: Int, discount: Discount) -> EndpointResponse<Discount> {
        guard let data = try? JSONEncoder().encode(discount),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return (Promise<Discount>(error: Error(.invalidDataEncoding)), { })
        }

        return self.update(
            endpoint: "/me/discounts/\(id)",
            parameters: dict
        )
    }
}
