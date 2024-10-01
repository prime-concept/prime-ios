import Alamofire
import Foundation
import PromiseKit

protocol DocumentsEndpointProtocol {
    func getDocs() -> EndpointResponse<Documents>
    func removeDocument(with id: Int) -> EndpointResponse<EmptyResponse>
    func create(document: Document) -> EndpointResponse<Document>
    func update(id: Int, document: Document) -> EndpointResponse<Document>
    func attachVisa(id: Int, passportId: Int) -> EndpointResponse<EmptyResponse>
}

final class DocumentsEndpoint: PrimeListsEndpoint, DocumentsEndpointProtocol {
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

    func getDocs() -> EndpointResponse<Documents> {
        return self.retrieve(endpoint: "/me/documents")
    }

    func removeDocument(with id: Int) -> EndpointResponse<EmptyResponse> {
        return self.remove(endpoint: "/me/documents/\(id)")
    }

    func create(document: Document) -> EndpointResponse<Document> {
        guard let data = try? JSONEncoder().encode(document),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return (Promise<Document>(error: Error(.requestRejected, details: "invalidDocumentEncode")), { })
        }

        return self.create(
            endpoint: "/me/documents",
            parameters: dict,
            encoding: JSONEncoding.default
        )
    }

    func update(id: Int, document: Document) -> EndpointResponse<Document> {
        guard let data = try? JSONEncoder().encode(document),
              let dict = try? JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
			return (Promise<Document>(error: Error(.invalidDataEncoding)), { })
        }

        return self.update(
            endpoint: "/me/documents/\(id)",
            parameters: dict
        )
    }

    func attachVisa(id: Int, passportId: Int) -> EndpointResponse<EmptyResponse> {
        return self.create(
            endpoint: "/me/documents/add_to_passport",
            parameters: [
                "documentId": "\(id)",
                "passportId": "\(passportId)"
            ]
        )
    }
}
