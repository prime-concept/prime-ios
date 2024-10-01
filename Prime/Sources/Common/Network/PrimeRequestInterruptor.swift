import Alamofire

final class PrimeRequestInterruptor: RequestAdapter, RequestRetrier {
    private static let unauthorizedCode = 401

    private let authService: LocalAuthServiceProtocol
    private let authEndpoint: AuthEndpointProtocol

    private var lock = NSLock()
    private var isRefreshing = false
    private var requestsToRetry = [RequestRetryCompletion]()

    init(authService: LocalAuthServiceProtocol, authEndpoint: AuthEndpointProtocol) {
        self.authService = authService
        self.authEndpoint = authEndpoint
    }

    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest

        guard let token = self.authService.token else {
            return urlRequest
        }

        urlRequest.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")

        return urlRequest
    }

    func should(
        _ manager: SessionManager,
        retry request: Request,
        with error: Error,
        completion: @escaping RequestRetryCompletion
    ) {
        let error = error as NSError

        guard error.code == Self.unauthorizedCode else {
            completion(false, 0)
            return
        }

        self.requestsToRetry.append(completion)

        guard !self.isRefreshing else {
            return
        }

        guard let token = self.authService.token else {
            completion(false, 0)
            return
        }

        self.isRefreshing = true
        self.authEndpoint.refreshOauthToken(with: token.refreshToken).result
        .done { [weak self] newToken in
            self?.authService.updateToken(accessToken: newToken)
            self?.requestsToRetry.forEach { $0(true, 0) }
        }.catch { [weak self] _ in
            self?.requestsToRetry.forEach { $0(false, 0) }
        }
        .finally { [weak self] in
            self?.requestsToRetry.removeAll()
            self?.isRefreshing = false
        }
    }
}
