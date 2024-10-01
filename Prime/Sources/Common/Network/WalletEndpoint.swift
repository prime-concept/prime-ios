import Alamofire
import PromiseKit

protocol WalletEndpointProtocol {
    func getWalletCardDownloadInfo() -> EndpointResponse<WalletCardDownloadInfo>
    func loadPKPassData(url: URL) -> Promise<Data>
}

final class WalletEndpoint: Endpoint, WalletEndpointProtocol {
    static let endpoint = "\(Config.walletEndpoint)/wallet/v1"

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

	override var notifiesServiceUnreachable: Bool {
		false
	}

    func getWalletCardDownloadInfo() -> EndpointResponse<WalletCardDownloadInfo> {
        self.create(endpoint: "/cards", parameters: ["redirect": "false"])
    }

    func loadPKPassData(url: URL) -> Promise<Data> {
        Promise<Data> { seal in
            Alamofire.request(url).validate().responseData(
                completionHandler: { response in
                    switch response.result {
                    case .failure(let error):
                        seal.reject(error)
                    case .success(let data):
                        seal.fulfill(data)
                    }
                }
            )
        }
    }
}
