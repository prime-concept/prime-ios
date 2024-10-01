import Foundation
import RestaurantSDK
import PromiseKit
import Alamofire

protocol BookerEndpointProtocol {
	func create(booking:  RestaurantSDK.BookerInput) -> EndpointResponse<EmptyResponse>
}

final class BookerEndpoint: PrimeEndpoint, BookerEndpointProtocol {
	private static let bookerEndpoint = "/api/booker"

	// Оставляем shared, это безопасно, тк тут нет стейта зависимого от сессии юзера
	static let shared = BookerEndpoint()

	override var notifiesServiceUnreachable: Bool {
		false
	}
	
	func create(booking: RestaurantSDK.BookerInput) -> EndpointResponse<EmptyResponse> {
		guard let data = try? JSONEncoder().encode(booking),
			  let dict = try? JSONSerialization
				.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
			return (Promise<EmptyResponse>(error: Error(.requestRejected, details: "Invalid booker input")), { })
		}

		return self.create(
			endpoint: Self.bookerEndpoint + "/create",
			parameters: dict,
			encoding: JSONEncoding.default
		)
	}
}
