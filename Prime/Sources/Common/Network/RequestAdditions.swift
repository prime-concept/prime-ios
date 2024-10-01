import Alamofire
import PromiseKit

final class PrimeRequestAdapter: RequestAdapter {
	private let authService: LocalAuthServiceProtocol

	init(authService: LocalAuthServiceProtocol) {
		self.authService = authService
	}

	func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
		var urlRequest = urlRequest

		self.insertTokenIfNeeded(in: &urlRequest)
		self.insertLangIfNeeded(in: &urlRequest)

		return urlRequest
	}
}

private extension PrimeRequestAdapter {
	private func insertTokenIfNeeded(in urlRequest: inout URLRequest) {
		if let token = self.authService.token {
			urlRequest.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
		}
	}

	private func insertLangIfNeeded(in urlRequest: inout URLRequest) {
		guard let url = urlRequest.url,
			  var components = URLComponents(string: url.absoluteString) else {
			return
		}

		var queryItems = components.percentEncodedQueryItems ?? []
		if queryItems.contains(where: { $0.name == "lang" }) {
			return
		}

		queryItems.append(URLQueryItem(name: "lang", value: Locale.primeLanguageCode))
		components.percentEncodedQueryItems = queryItems

		guard let url = components.url else {
			return
		}

		urlRequest.url = url
	}
}

// Здесь происходит наше обновление токена. Оно cделано не через refreshToken.
// По сути, при истечении токена, мы в фоне повторно авторизуемся по пинкоду,
// и в результате нам приходит новый токен.
final class TokenExpirationRetrier: RequestRetrier {
	private var isRefreshing = false

	private let authService: LocalAuthServiceProtocol
	private let authEndpoint: AuthEndpointProtocol

	private let sharedStateAccessQueue = DispatchQueue(label: "TokenExpirationRetrier.sharedStateAccessQueue")
	private var requestsToRetry = [RequestRetryCompletion]()
	private var retriesWaitingInternet: [(URLRequest, () -> Void)] = []

	static let shared = TokenExpirationRetrier(
		authService: LocalAuthService(),
		authEndpoint: AuthEndpoint()
	)

	private init(authService: LocalAuthServiceProtocol, authEndpoint: AuthEndpointProtocol) {
		self.authService = authService
		self.authEndpoint = authEndpoint

		Notification.onReceive(.networkReachabilityChanged) { _ in
            self.sharedStateAccessQueue.async {
                guard NetworkMonitor.shared.isConnected else {
                    return
                }

                self.retriesWaitingInternet.forEach { $0.1() }
                self.retriesWaitingInternet.removeAll()
            }
		}
	}

	func should(
		_ manager: SessionManager,
		retry request: Request,
		with error: Error,
		completion: @escaping RequestRetryCompletion
	) {
        self.sharedStateAccessQueue.async {
            DebugUtils.shared.log(sender: self, "Encountered error: \(error), code: \(error.code)")

            guard let username = self.authService.user?.username else {
                DebugUtils.shared.log(sender: self, "USER HAS NO USERNAME, SKIP TOKEN RETRY")
                completion(false, 0)
                return
            }

            if !NetworkMonitor.shared.isConnected, let _ = request.request {
                DebugUtils.shared.log(sender: self, "DETECTED NO INTERNET!")
                self.enqueueRequestAndCallWhenInternetRestores(
                    manager: manager, retry: request, with: error, completion: completion
                )
                return
            }

            guard error.code == 401 else {
                DebugUtils.shared.log(sender: self, "Will resign, error code: \(error.code)")
                completion(false, 0)
                return
            }

            if error.isChangedPinToken {
                DebugUtils.shared.log(sender: self, "will resign")

                NotificationCenter.default.post(
                    name: .failedToRefreshToken,
                    object: nil,
                    userInfo: ["error": error]
                )
                return
            }

            DebugUtils.shared.log(sender: self, "will handle error \(error)")

            self.requestsToRetry.append(completion)

			if self.isRefreshing {
				return
			}

			let pinCode = self.authService.pinCode ?? ""
            self.refreshOauthToken(username: username, pinCode: pinCode)
		}
	}

	private func enqueueRequestAndCallWhenInternetRestores(
		manager: SessionManager,
		retry request: Request,
		with error: Error,
		completion: @escaping RequestRetryCompletion
	) {
        self.sharedStateAccessQueue.async {
            guard let urlRequest = request.request else { return }

            if self.retriesWaitingInternet.contains(where: { $0.0 == urlRequest }) {
                completion(false, 0)
                return
            }

            DebugUtils.shared.log(sender: self, "WILL PUT REQUEST\n\(urlRequest)\nTO WAITING LIST!")

            let retryBlock = { [weak self, weak manager] in
                guard let self = self, let manager = manager else {
                    completion(false, 0)
                    return
                }
                self.should(manager, retry: request, with: error, completion: completion)
            }

            self.retriesWaitingInternet.append((urlRequest, retryBlock))

            completion(false, 0)
        }
	}

	private func refreshOauthToken(username: String, pinCode: String) {
        self.indicateTokenRefreshWillStart()

        self.sharedStateAccessQueue.promise {
            self.authEndpoint.refreshOauthToken(username: username, code: pinCode).promise
        }.done(on: self.sharedStateAccessQueue) { [weak self] accessToken in
            self?.handleRefreshSucceeded(accessToken: accessToken)
		}.catch(on: self.sharedStateAccessQueue) { [weak self] error in
            self?.handleRefreshFailed(error: error)
		}.finally(on: self.sharedStateAccessQueue) { [weak self] in
			self?.isRefreshing = false
			LocalAuthService.tokenNeedsToBeRefreshed = false
		}
	}

    private func indicateTokenRefreshWillStart() {
        self.sharedStateAccessQueue.async {
            self.isRefreshing = true
            LocalAuthService.tokenNeedsToBeRefreshed = true

            DebugUtils.shared.log(sender: self, "will fetchOauthToken")
            AnalyticsReportingService.shared.log(error: "[TOKEN] Will refresh token")
        }
    }

    private func callAndClearRequestsCompletions(success: Bool) {
        self.requestsToRetry.forEach { $0(success, 0) }
        self.requestsToRetry.removeAll()
    }

    private func handleRefreshSucceeded(accessToken: AccessToken) {
        self.authService.update(token: accessToken)

        AnalyticsReportingService.shared.log(error: "[TOKEN] Refresh success")
        DebugUtils.shared.log(sender: self, "successfully fetched oauth token")

        self.callAndClearRequestsCompletions(success: true)
    }

    private func handleRefreshFailed(error: Error) {
        self.callAndClearRequestsCompletions(success: false)

        AnalyticsReportingService.shared.log(
            name: "[TOKEN] Refresh failed \(error.isChangedPinToken ? "(PIN Changed)" : "")",
            parameters: error.asDictionary
        )

        if error.isChangedPinToken || error.isNoRefreshToken || error.isDeletedUserToken {
            self.notifyResfreshFailed(error)
        }
    }

    private func notifyResfreshFailed(_ error: Error) {
        DebugUtils.shared.log(sender: self, "will resign after failed fetch attempt \(error)")

        NotificationCenter.default.post(
            name: .failedToRefreshToken,
            object: nil,
            userInfo: ["error": error]
        )
    }
}
