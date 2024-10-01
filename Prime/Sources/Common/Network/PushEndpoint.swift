import Foundation
import PromiseKit
import Alamofire

protocol PushEndpointProtocol {
    func register(token: String) -> EndpointResponse<EmptyResponse>
}

final class PushEndpoint: PrimeEndpoint, PushEndpointProtocol {
    private static let registerEndpoint = "/fcm/register"

	override var notifiesServiceUnreachable: Bool {
		false
	}

    func register(token: String) -> EndpointResponse<EmptyResponse> {
        var params = self.paramsWithCredentials
        params["token"] = token
        return self.create(endpoint: Self.registerEndpoint, parameters: params)
    }
}
