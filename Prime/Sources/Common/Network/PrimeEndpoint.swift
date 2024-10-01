import UIKit
import CommonCrypto
import Alamofire

protocol PrimeEndpointProtocol {
    var paramsWithCredentials: [String: Any] { get }
    var paramsString: String { get }
    var authHeaders: [String: String] { get }
}

class PrimeEndpoint: Endpoint, PrimeEndpointProtocol {
    static let endpoint = "\(Config.crmEndpoint)/artoflife/v4"

    init() {
        super.init(
            basePath: Self.endpoint,
            requestAdapter: PrimeRequestAdapter(authService: LocalAuthService()),
            requestRetrier: TokenExpirationRetrier.shared
        )
    }

	required init(
		basePath: String,
		requestAdapter: RequestAdapter? = nil,
		requestRetrier: RequestRetrier? = nil
	) {
		super.init(
			basePath: basePath,
			requestAdapter: requestAdapter,
			requestRetrier: requestRetrier
		)
	}
}

class PrimeListsEndpoint: Endpoint, PrimeEndpointProtocol {
    static let endpoint = "\(Config.crmEndpoint)/artoflife/v4"

    init() {
        super.init(
            basePath: Self.endpoint,
            requestAdapter: PrimeRequestAdapter(authService: LocalAuthService()),
            requestRetrier: TokenExpirationRetrier.shared
        )
    }

	required init(
		basePath: String,
		requestAdapter: RequestAdapter? = nil,
		requestRetrier: RequestRetrier? = nil
	) {
		super.init(
			basePath: basePath,
			requestAdapter: requestAdapter,
			requestRetrier: requestRetrier
		)
	}
}

// Зачем нужно разбиение на PrimeEndpoint и PrimeEndpointProtocol с дефолтными реализациями?
// Дело в том, что в конструкторе эндпоинта используется retrier, который в свою очередь использует AuthEndpoint.
// А AuthEndpoint наследуется от Endpoint, и без разделения это приводило к переполнению стека и крашу.
extension PrimeEndpointProtocol {
    var paramsWithCredentials: [String: Any] {
		[
			"client_id": Config.clientID,
			"device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
		]
	}

    var paramsString: String {
        var result = ""
        result += self.paramsWithCredentials["client_id"] as? String ?? ""
        result += self.paramsWithCredentials["device_id"] as? String ?? ""
        return result
    }

    var authHeaders: [String: String] {
		let authString = "\(Config.clientID):\(Config.clientSecret)"
        guard let token = authString.data(using: .utf8)?.base64EncodedString() else {
            fatalError("It shouldn`t crash")
        }
        return ["Authorization": "Basic \(token)"]
    }
}

