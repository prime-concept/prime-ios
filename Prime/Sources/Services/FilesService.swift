import PromiseKit

// MARK: - FilesServiceProtocol

protocol FilesServiceProtocol: AnyObject {
	func list(forDocument id: Int) -> Promise<FilesResponse>
    func list(forTask id: Int) -> Promise<FilesResponse>
	func listForProfilePicture() -> Promise<FilesResponse>
	func upload(forDocument id: Int, data: Data) -> Promise<FilesResponse.File>
	func upload(profilePicture data: Data) -> Promise<FilesResponse.File>
    func image(byUUID uuid: String) -> Promise<UIImage>
	func downloadData(uuid: String) -> Promise<Data>
	func thumbnail(uuid: String) -> Promise<UIImage?>
	func remove(uuid: String) -> Promise<Void>
}

// MARK: - FilesService

final class FilesService: FilesServiceProtocol {
	// Оставляем shared, но очищаем хранимые данные при разлогине/очистке кэша
    static let shared = FilesService(endpoint: FilesEndpoint(authService: LocalAuthService.shared))

	private let endpoint: FilesEndpointProtocol

	@ThreadSafe
	private static var fullImageCache: [String: UIImage?] = [:]

	init(endpoint: FilesEndpointProtocol) {
		self.endpoint = endpoint

		Notification.onReceive(.shouldClearCache, .loggedOut) { _ in
			Self.fullImageCache.removeAll()
		}
	}

	func list(forDocument id: Int) -> Promise<FilesResponse> {
		DispatchQueue.global().promise {
			self.endpoint.listFor(document: id).promise
		}
	}
    
    func list(forTask id: Int) -> Promise<FilesResponse> {
        DispatchQueue.global().promise {
            self.endpoint.listFor(task: id).promise
        }
    }

	func listForProfilePicture() -> Promise<FilesResponse> {
		DispatchQueue.global().promise {
			self.endpoint.listForProfilePicture().promise
		}
	}

	func upload(forDocument id: Int, data: Data) -> Promise<FilesResponse.File> {
		DispatchQueue.global().promise {
			self.endpoint.upload(document: id, data: data).promise
		}
	}

	func upload(profilePicture data: Data) -> Promise<FilesResponse.File> {
		DispatchQueue.global().promise {
			self.endpoint.upload(profilePicture: data).promise
		}
	}
    
    func image(byUUID uuid: String) -> Promise<UIImage> {
        if let cached = cachedImage(byUUID: uuid) {
            return Promise.value(cached)
        } else {
            return downloadImage(byUUID: uuid)
        }
    }
    
    private func cachedImage(byUUID uuid: String) -> UIImage? {
        Self.fullImageCache[uuid] ?? nil
    }
    
    private func downloadImage(byUUID uuid: String) -> Promise<UIImage> {
        return DispatchQueue.global().promise {
            self.endpoint.download(uuid: uuid).promise
        }
        .map { data in
            guard let image = UIImage(data: data) else {
                throw FilesServiceError.failedToInitializeImageFromData
            }
            Self.fullImageCache[uuid] = image
            return image
        }
    }

	func downloadData(uuid: String) -> Promise<Data> {
		return DispatchQueue.global().promise {
			self.endpoint.download(uuid: uuid).promise
		}
	}

	func thumbnail(uuid: String) -> Promise<UIImage?> {
		DispatchQueue.global().promise {
			self.endpoint.thumbnail(uuid: uuid).promise
		}
        .map { data in
            UIImage.init(data: data)
        }
	}

	func remove(uuid: String) -> Promise<Void> {
		DispatchQueue.global().promise {
			self.endpoint.remove(uuid: uuid).promise
        }.map { _ in
            ()
        }
	}
}

// MARK: - FilesServiceError

fileprivate enum FilesServiceError: LocalizedError {
    
    case fileCouldNotBeDownloaded
    case failedToInitializeImageFromData
    
    var errorDescription: String? {
        switch self {
        case .fileCouldNotBeDownloaded: "Failed to download the file"
        case .failedToInitializeImageFromData: "Failed to initialize an image from data"
        }
    }
    
}
