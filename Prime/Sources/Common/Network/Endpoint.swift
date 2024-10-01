import Alamofire
import Foundation
import PromiseKit
import UIKit

extension Notification.Name {
	static let networkEventOccured = Notification.Name("networkEventOccured")
}

/// Отмена пока что не работает
typealias CancellationToken = () -> Void
/// Отмена пока что не работает
typealias EndpointResponse<T> = (promise: Promise<T>, cancellation: CancellationToken)

/// Отмена пока что не работает
private typealias EndpointResponseWithCURL<T> = (promise: Promise<(String?, T)>, cancellation: CancellationToken)

protocol CachingEnpointProtocol {
	var cache: Self { get }
}

class Endpoint: CachingEnpointProtocol {
	enum DataSource {
		case server
		case cache
	}

	struct UploadableFile: Decodable {
		let data: Data
		let name: String
		let fileName: String
		let mimeType: String
	}

	private let basePath: String
	private lazy var manager = SessionManager(configuration: self.sessionConfiguration)
	private lazy var sessionConfiguration: URLSessionConfiguration = {
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = 30
		return configuration
	}()

	private var _cache: Endpoint?

	var cache: Self {
		if let cache = _cache as? Self {
			return cache
		}
		let endpoint = Self(
			basePath: self.basePath,
			requestAdapter: self.manager.adapter,
			requestRetrier: self.manager.retrier
		)
		endpoint.dataSource = .cache
		_cache = endpoint

		return endpoint
	}

	var notifiesServiceUnreachable: Bool {
		true
	}

	var mayLogToGoogle: Bool {
		true
	}

	var needsTokenToExecuteRequests: Bool {
		true
	}

    var usesResponseCache: Bool {
        true
    }

	private static var requestsWaitingForToken = [() -> Void]()
	private static let requestsWaitingSyncQueue: DispatchQueue = {
		return DispatchQueue(
			label: "Endpoint.backgroundWaitableOperationsSyncQueue",
			qos: .default
		)
	}()

	fileprivate(set) var dataSource: DataSource = .server

	private static let tokenSubscription: Void = {
		Notification.onReceive(.didRefreshToken) { notification in
			requestsWaitingSyncQueue.async {
				let accessToken = notification.userInfo?["access_token"] ?? ""
                let refreshToken = notification.userInfo?["refresh_token"] ?? ""

				DebugUtils.shared.log("[STATIC ENDPOINT] DID REFRESH ACCESS TOKEN: \(accessToken), REFRESH: \(refreshToken) WILL EXECUTE \(requestsWaitingForToken.count) REQUESTS!")

				for request in requestsWaitingForToken {
					request()
				}
				requestsWaitingForToken.removeAll()
			}
		}

		Notification.onReceive(.failedToRefreshToken, .loggedOut, .shouldClearCache) { notification in
			DebugUtils.shared.log("[STATIC ENDPOINT] DID CANCEL TOKEN REFRESHING, REASON: \(notification.name)")
			requestsWaitingForToken.removeAll()
		}
	}()

	required init(
		basePath: String,
		requestAdapter: RequestAdapter? = nil,
		requestRetrier: RequestRetrier? = nil
	) {
		self.basePath = basePath
		self.manager.adapter = requestAdapter
		self.manager.retrier = requestRetrier

		self.manager.startRequestsImmediately = false

		Self.tokenSubscription
	}

    // MARK: - Common

    private func requestRawData(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        encoding: ParameterEncoding
	) -> EndpointResponseWithCURL<Data> {
		var isCancelled = false
		var dataRequest: DataRequest?
		
		let promise = Promise<(String?, Data)> { [weak self] seal in
			guard let self = self else {
				seal.reject(Error(.requestRejected, details: "Endpoint self == nil"))
				return
			}

			let request = self.manager.request(
				self.makeFullPath(endpoint: endpoint),
				method: method,
				parameters: parameters,
				encoding: encoding,
				headers: headers
			)

			let url = request.request?.url
			let cURL = request.request?.cURL
			let curlOrURL = cURL ?? url?.absoluteString

			cURL.some { DebugUtils.shared.log($0, mayLogToGoogle: self.mayLogToGoogle) }

			if self.dataSource == .cache, self.usesResponseCache {
				if let url = url, 
				   let data = ResponseCacheService.shared.data(for: url, parameters: parameters)
				{
					seal.fulfill((cURL, data))
				} else {
					seal.reject(Error(.noCachedData, curl: curlOrURL))
				}
				return
			}

			let waitableDataFetchBlock = { [weak self] in
				guard let self = self else {
					seal.reject(Error(.requestRejected, curl: curlOrURL, details: "Endpoint self == nil"))
					return
				}

				let request = self.manager.request(
					self.makeFullPath(endpoint: endpoint),
					method: method,
					parameters: parameters,
					encoding: encoding,
					headers: headers
				)

				dataRequest = request
				request
					.validate(self.validateResponse)
					.responseData { response in
						if isCancelled {
							seal.reject(Error(.requestRejected, curl: curlOrURL, details: "Request cancelled"))
							return
						}

						let handler = { [weak self] (error: Swift.Error) in
							guard let self = self else { return }
							
							DebugUtils.shared.log(sender: self, "[DELEGATE] ERROR OCCURED FOR REQUEST:\n\(cURL ?? "")\n\(error)")

							if self.notifiesServiceUnreachable, UIApplication.shared.applicationState == .active {
								DebugUtils.shared.log(sender: self, "[DELEGATE] ERROR OCCURED FOR REQUEST:\n\(cURL ?? "")\n\(error) WILL NOTIFY APP, SHOW RED/YELLOW BADGE")
								Notification.post(.networkEventOccured, userInfo: ["error": error])
							}

                            if !NetworkMonitor.shared.isConnected, self.usesResponseCache, let url = url, let data = ResponseCacheService.shared.data(for: url, parameters: parameters) {
								DebugUtils.shared.log(sender: self, "[DELEGATE] NO INTERNET + CACHED DATA EXISTS SO CONSIDER IT A FULFILL")
								seal.fulfill((cURL, data))
								return
							}
						}

						if let error = dataRequest?.delegate.error {
							handler(error)
                            seal.reject(Error(.requestFailed, curl: curlOrURL, rawError: error))
							return
						}

						switch response.result {
							case .failure(let error):
								DebugUtils.shared.log(sender: self, "[RESULT] ERROR OCCURED FOR REQUEST:\n\(cURL ?? "")\n\(error)")
								handler(error)
								seal.reject(Error(.requestFailed, curl: curlOrURL, rawError: error))
							case .success(let data):
								Notification.post(.networkEventOccured, userInfo: [:])
								if self.usesResponseCache {
									ResponseCacheService.shared.write(data: data, for: url, parameters: parameters)
								}
								seal.fulfill((cURL, data))
						}
					}

				request.resume()
			}

			if self.dataSource != .cache, LocalAuthService.tokenNeedsToBeRefreshed, self.needsTokenToExecuteRequests {
				DebugUtils.shared.log(sender: self, "ACCESS TOKEN IS BEING REFRESHED, WILL PUT REQUEST TO WAITING LIST: \(cURL ?? "")")
				Self.requestsWaitingSyncQueue.async {
					Endpoint.requestsWaitingForToken.append(waitableDataFetchBlock)
				}
				return
			}

			waitableDataFetchBlock()
		}
		
		let cancellation = {
			isCancelled = true
			dataRequest?.cancel()
		}

		// Отмена пока что не работает
		return (promise, cancellation)
	}

    // MARK: - Create (POST)

    func create<V: Decodable>(
        endpoint: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        encoding: ParameterEncoding = URLEncoding.default
    ) -> EndpointResponse<V> {
		self.request(
			endpoint: endpoint,
			method: .post,
			parameters: parameters,
			headers: headers,
			encoding: encoding
		)
    }

    // MARK: - Retrieve (GET)

    func retrieve<V: Decodable>(
        endpoint: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil
    ) -> EndpointResponse<V> {
		self.request(
			endpoint: endpoint,
			method: .get,
			parameters: parameters,
			headers: headers,
			encoding: URLEncoding.default
		)
    }

    // MARK: - Update (PUT)

    func update<V: Decodable>(
        endpoint: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil
    ) -> EndpointResponse<V> {
		self.request(
			endpoint: endpoint,
			method: .put,
			parameters: parameters,
			headers: headers,
			encoding: JSONEncoding.default
		)
    }

    // MARK: - Remove (DELETE)

    func remove<V: Decodable>(
        endpoint: String,
        method: HTTPMethod = .delete,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        encoding: ParameterEncoding = JSONEncoding.default
    ) -> EndpointResponse<V> {
		self.request(
			endpoint: endpoint,
			method: method,
			parameters: parameters,
			headers: headers,
			encoding: encoding
		)
    }

    // MARK: - Upload

	func uploadFile<V: Decodable>(
		file: UploadableFile,
		endpoint: String,
		headers: HTTPHeaders? = nil
	) -> EndpointResponse<V> {
		let (promise, cancellation) = self.upload(
			file: file,
			endpoint: endpoint,
			headers: headers
		)

		let responsePromise: Promise<V> = self.executeAndDecodeData(
			from: promise
		)

		// Отмена пока что не работает
		return (responsePromise, cancellation)
	}

    // MARK: - Download

    func downloadFile(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil
    ) -> EndpointResponse<Data> {
		let promise = self.requestRawData(
            endpoint: endpoint,
            method: method,
            parameters: parameters,
            headers: headers,
            encoding: URLEncoding.default
		)

		// Отмена пока что не работает
		return (promise.promise.map(\.1), promise.cancellation)
    }

	private func request<V: Decodable>(
		endpoint: String,
		method: HTTPMethod,
		parameters: Parameters? = nil,
		headers: HTTPHeaders? = nil,
		encoding: ParameterEncoding = JSONEncoding.default
	) -> EndpointResponse<V> {
		let (promise, cancellation) = self.requestRawData(
			endpoint: endpoint,
			method: method,
			parameters: parameters,
			headers: headers,
			encoding: encoding
		)

		let responsePromise: Promise<V> = self.executeAndDecodeData(
			from: promise
		)

		// Отмена пока что не работает
		return (responsePromise, cancellation)
	}

	private func upload(
		file: UploadableFile,
		endpoint: String,
		headers: HTTPHeaders? = nil
	) -> EndpointResponseWithCURL<Data> {
		var uploadRequest: UploadRequest?
		var isCancelled = false

		let cancellation = {
			isCancelled = true
			uploadRequest?.cancel()
		}

		let formDataAppender = { (formData: MultipartFormData) in
			formData.append(
				file.data,
				withName: file.name,
				fileName: file.fileName,
				mimeType: file.mimeType
			)
		}
		
		DebugUtils.shared.log(sender: self, "WILL UPLOAD FILE TO \(endpoint)")

		let promise = Promise<(String?, Data)> { seal in
			let waitableDataFetchBlock = { [weak self] in
				guard let self = self else {
					seal.reject(Error(.requestRejected, details: "Endpoint self == nil"))
					return
				}
				self.manager.upload(
					multipartFormData: formDataAppender,
					to: self.makeFullPath(endpoint: endpoint),
					headers: headers,
					encodingCompletion: { result in
						guard case let .success(request, _, _) = result else {
							if case let .failure(error) = result {
								seal.reject(Error(.requestRejected, details: "UPLOAD FILE TO \(endpoint)", rawError: error))
								return
							}
							seal.reject(Error(.requestRejected, details: "UPLOAD FILE TO \(endpoint)"))
							return
						}

						let url = request.request?.url
						let cURL = request.request?.cURL
						let curlOrURL = cURL ?? url?.absoluteString
						cURL.flatMap{ DebugUtils.shared.log($0, mayLogToGoogle: self.mayLogToGoogle) }

						uploadRequest = request
						request
							.validate(self.validateResponse)
							.responseData { response in
								if isCancelled {
									seal.reject(Error(.requestRejected, curl: curlOrURL, details: "Request is cancelled"))
									return
								}
								//swiftlint:disable switch_case_alignment
								switch response.result {
								case .failure(let error):
									DebugUtils.shared.log(sender: self, "[UPLOAD RESULT] ERROR OCCURED FOR REQUEST:\n\(cURL ?? "")\n\(error)")
									seal.reject(Error(.requestRejected, details: "UPLOAD FILE TO \(endpoint)"))
								case .success(let data):
									seal.fulfill((cURL, data))
								}
								//swiftlint:enable switch_case_alignment
							}

						request.resume()
					}
				)
			}

			if self.dataSource != .cache, LocalAuthService.tokenNeedsToBeRefreshed, self.needsTokenToExecuteRequests {
				DebugUtils.shared.log(sender: self, "ACCESS TOKEN IS BEING REFRESHED, WILL PUT REQUEST TO WAITING LIST")
				Self.requestsWaitingSyncQueue.async {
					Endpoint.requestsWaitingForToken.append(waitableDataFetchBlock)
				}
				return
			}

			waitableDataFetchBlock()
		}

		// Отмена пока что не работает
		return (promise, cancellation)
	}

    // MARK: - Private API

    private func makeFullPath(endpoint: String) -> String {
        "\(self.basePath)\(endpoint)"
    }

    private func executeAndDecodeData<T: Decodable>(
        from promise: Promise<(String?, Data)>
    ) -> Promise<T> {
        return Promise<T> { seal in
			promise.done(on: DispatchQueue.global()) { tuple in
				let cURL = tuple.0
				var data = tuple.1

				let responseString = String(data: data, encoding: .utf8) ?? ""

                self.fixInvalidData(in: &data)
				self.printResponse(cURL: cURL, string: responseString)

				do {
					let object: T = try self.objectFromJSON(data: data)
					seal.fulfill(object)
				} catch let error {
					let errorDetails = self.mayLogToGoogle ? responseString : ""
					seal.reject(Error(.decodeFailed, curl: cURL, details: errorDetails, rawError: error))
				}
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    // MARK: - Utils
	private lazy var decoder = with(JSONDecoder()) { decoder in
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)

		decoder.dateDecodingStrategy = .custom { decoder -> Date in
			let container = try decoder.singleValueContainer()
			let dateString = try container.decode(String.self)

			if let date = dateString.serverDate {
				return date
			}
			throw Error(.invalidDateDecoding)
		}
	}

    private func fixInvalidData(in data: inout Data) {
        // Хак для невалидного json'а с бэка: добавим символов для того чтоб ответ мог парситься хотя бы
        if data.first != 123 && data.first != 91 { // 123 == '{' 91 == '['
            data.insert(contentsOf: [123, 34, 95, 34, 58, 34], at: 0) // дописываем {"_":"
            data.append(contentsOf: [34, 125]) // дописываем "}
        }
    }

	private func printResponse(cURL: String? = nil, string: String) {
		let responseString = string
		DebugUtils.shared.log(sender: self, "RESPONSE for\n\(cURL^)\nis\n\(responseString)", mayLogToGoogle: self.mayLogToGoogle)
    }

	private static let diffFormatter = with(NumberFormatter()) {
		$0.maximumFractionDigits = 10
	}

    private func objectFromJSON<T: Decodable>(data: Data) throws -> T {
		let start = CFAbsoluteTimeGetCurrent()
		let object = try self.decoder.decode(T.self, from: data)
		let diff = CFAbsoluteTimeGetCurrent() - start
		let seconds = Self.diffFormatter.string(from: NSNumber(floatLiteral: diff)) ?? "NaN"

		DebugUtils.shared.log(sender: self, "Decoding took \(diff) aka \(seconds) seconds")
		return object
    }

    private func validateResponse(
        request: URLRequest?,
        response: HTTPURLResponse,
        data: Data?
    ) -> Request.ValidationResult {
        if (200..<300).contains(response.statusCode) {
            return .success
        }

        guard let data = data else {
            return .failure(Error(.emptyResponse))
        }

        if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return .failure(self.makeNSError(code: response.statusCode, message: error.description))
        }

        let message = String(data: data, encoding: .utf8) ?? "Error"
        return .failure(self.makeNSError(code: response.statusCode, message: message))
    }

    private func makeNSError(code: Int, message: String) -> NSError {
        NSError(
            domain: Bundle.main.bundleIdentifier ?? "com.nserror",
            code: code,
            userInfo: [
                NSLocalizedDescriptionKey: message
            ]
        )
    }

    // MARK: - Enums

	struct Error: Swift.Error {
		enum Kind: String {
			case swiftError
			case defaultError

			case invalidURL
			case invalidDataEncoding
			case invalidDateDecoding

			case noCachedData
			case emptyResponse

			case requestFailed
			case requestRejected

			case decodeFailed
		}

		var type: Kind
		var curl: String?
		var response: String?

		var code: Int?
		var details: String?

		var rawError: Swift.Error? = nil

		init(dictionary: [String: Any]) {
			self.init(
				.defaultError,
				curl: dictionary["curl"] as? String,
				response: dictionary["response"] as? String,
				details: dictionary["details"] as? String,
				rawError: dictionary["error"] as? Swift.Error
			)
		}

		init(
			_ type: Endpoint.Error.Kind,
			code: Int? = nil,
			curl: String? = nil,
			response: String? = nil,
			details: String? = nil,
			rawError: Swift.Error? = nil
		) {
			if let error = rawError as? Endpoint.Error {
				self.type = error.type
				self.code = error.code
				self.curl = error.curl
				self.response = error.response
				self.details = error.details
				self.rawError = error.rawError
				return
			}

			self.type = type
			self.code = code ?? rawError?.code
			self.curl = curl
			self.response = response
			self.details = details ?? rawError?.localizedDescription
			self.rawError = rawError
		}

		var asDictionary: [String: Any] {
			var dictionary = [String: Any]()
			dictionary["type"] = self.type.rawValue
			dictionary["code"] = self.code ?? self.rawError?.code
			dictionary["curl"] = self.curl
			dictionary["response"] = self.response

			var details = self.details ?? ""
			details.append("\n")
			details.append(self.rawError?.localizedDescription ?? "")

			if details.count > 1 {
				dictionary["details"] = details
			}

			return dictionary
		}
    }
}

extension Swift.Error {
	var asDictionary: [String: Any] {
		if let self = self as? Endpoint.Error {
			return self.asDictionary
		}

		let error = Endpoint.Error(.swiftError, rawError: self)
		return error.asDictionary
	}
}

extension Endpoint.Error {
	var isChangedPinToken: Bool {
		if let code = self.code, code == 400 {
			return self.details?.lowercased().contains("bad credentials") ?? false
		}

		if let code = self.code, code == 401 {
			return self.details?.lowercased().contains("password update") ?? false
		}

		return false
	}

	var isExpiredToken: Bool {
		if let code = self.code, code == 401 {
			return self.details?.lowercased().contains("invalid access token") ?? false
		}
		return false
	}

	var isDeletedUserToken: Bool {
		if let code = self.code, code == 401 {
			return self.details?.lowercased().contains("unable to find user by refresh token") ?? false
		}
		return false
	}
}

extension Dictionary {
	func appending(_ key: Key, _ value: Value?) -> Self {
		var result = self
		result[key] = value
		return result
	}
}

extension Encodable {
	var paramsDict: [String: Any]? {
		guard let data = try? JSONEncoder().encode(self) else {
			return nil
		}

		let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
		return dict as? [String: Any]
	}
}

extension Promise {
	static func rejectedResponse(_ details: String? = nil, _ cancellation: @escaping () -> Void = {}) -> EndpointResponse<T> {
		let error = Endpoint.Error(.requestRejected, details: details)
		let promise = self.init(error: error)

		let response = (promise, cancellation)

		return response
	}
}
