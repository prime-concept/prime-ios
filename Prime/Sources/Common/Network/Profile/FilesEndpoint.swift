import Alamofire
import Foundation
import PromiseKit

enum EndpointMimeType {
    case audio
    case video
    case vcard
    case plain
    case imageJPG
    case imagePNG
    case unknown
    case other(mimeType: String)

    var stringValue: String {
        switch self {
        case .audio:
            return "audio/mp4"
        case .video:
            return "video/mp4"
        case .vcard:
            return "text/x-vcard"
        case .plain:
            return "text/plain"
        case .imageJPG:
            return "image/jpeg"
        case .imagePNG:
            return "image/png"
        case .unknown:
            return "application/octet-stream"
        case .other(let mimeType):
            return mimeType
        }
    }
}

struct FilesResponse: Codable {
    struct File: Codable {
		let uid: String
		let fileName: String
		let contentType: String

		let size: Int
        let width: Int?
        let height: Int?

        let description: String?

		var cacheKey: String {
			self.uid + "/" + self.fileName
		}
    }
    
    let data: [File]?
    let error: String?
    let errorDescription: String?
}

protocol FilesEndpointProtocol {
	func listFor(document id: Int) -> EndpointResponse<FilesResponse>
	func listForProfilePicture() -> EndpointResponse<FilesResponse>
	func upload(document id: Int, data: Data) -> EndpointResponse<FilesResponse.File>
	func upload(profilePicture data: Data) -> EndpointResponse<FilesResponse.File>
	func download(uuid: String) -> EndpointResponse<Data>
	func thumbnail(uuid: String) -> EndpointResponse<Data>
	func remove(uuid: String) -> EndpointResponse<EmptyResponse>
    func listFor(task id: Int) -> EndpointResponse<FilesResponse>
}

final class FilesEndpoint: PrimeEndpoint, FilesEndpointProtocol {
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
	
    func listFor(task id: Int) -> EndpointResponse<FilesResponse> {
        self.listFor(path: "task/\(id)")
    }
    
	func listFor(document id: Int) -> EndpointResponse<FilesResponse> {
		self.listFor(path: "documents/\(id)")
	}

	func listForProfilePicture() -> EndpointResponse<FilesResponse> {
		self.listFor(path: "photo")
	}

	func upload(document id: Int, data: Data) -> EndpointResponse<FilesResponse.File> {
		self.upload(data: data, path: "documents/\(id)")
	}

	func upload(profilePicture data: Data) -> EndpointResponse<FilesResponse.File> {
		self.upload(data: data, path: "photo")
	}

	func download(uuid: String) -> EndpointResponse<Data> {
		self.download(path: "/files/download/\(uuid)")
	}

	func thumbnail(uuid: String) -> EndpointResponse<Data> {
		self.download(path: "/files/thumbnail/\(uuid)")
	}

	func remove(uuid: String) -> EndpointResponse<EmptyResponse> {
        return self.remove(endpoint: "/files/remove/\(uuid)", method: .get)
	}

	private func download(path: String) -> EndpointResponse<Data> {
		return self.downloadFile(endpoint: path)
	}

	private func listFor(path: String) -> EndpointResponse<FilesResponse> {
		return self.retrieve(
			endpoint: "/files/list",
			parameters: ["path": path]
		)
	}

    private func upload(data: Data, path: String) -> EndpointResponse<FilesResponse.File> {
        let endpoint = "/files/upload?path=" + path

        let uuid = UUID().uuidString
        let fileName = uuid + ".jpeg"

        let file = UploadableFile(
            data: data,
            name: "file",
            fileName: fileName,
            mimeType: "image/jpeg"
        )

        return self.uploadFile(
            file: file,
            endpoint: endpoint
        )
	}
}
