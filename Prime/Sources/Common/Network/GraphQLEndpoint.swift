import Foundation
import Alamofire

protocol GraphQLEndpointProtocol {
	var cache: Self { get }
    func request<T: Decodable>(
        query: String,
        variables: [String: AnyEncodable]
    ) -> EndpointResponse<T>
}

final class GraphQLEndpoint: Endpoint, GraphQLEndpointProtocol {
	private static let endpoint = "\(Config.crmEndpoint)/artoflife/v4/graphql"

    convenience init() {
        self.init(
            basePath: Self.endpoint,
            requestAdapter: PrimeRequestAdapter(authService: LocalAuthService()),
			requestRetrier: TokenExpirationRetrier.shared
        )
    }

    func request<T: Decodable>(
        query: String,
        variables: [String: AnyEncodable]
    ) -> EndpointResponse<T> {
        let request = GraphQL.Request(query: query, variables: variables)
        let parameters = self.makeDictionary(from: request)
        return self.create(
            endpoint: "",
            parameters: parameters,
            encoding: JSONEncoding.default
        )
    }

    // MARK: - Private

    func makeDictionary<T: Encodable>(from object: T) -> [String: Any] {
        // swiftlint:disable force_try force_cast
       let encoder = JSONEncoder()
       encoder.dateEncodingStrategy = .iso8601
       let data = try! encoder.encode(object)
       let dictionary = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
       // swiftlint:enable force_try force_cast
       return dictionary
    }
}
