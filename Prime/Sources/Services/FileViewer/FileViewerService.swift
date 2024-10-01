import UIKit
import AVKit

class FileViewerService {
	static let shared = FileViewerService()
	
	private let filesService = FilesService.shared
	private let cacheService = DocumentsCacheService.shared

	private lazy var avPlayer = AVPlayerViewController()

	private let queue = DispatchQueue(label: "FileViewerService", qos: .userInitiated)

	func viewer(for file: FilesResponse.File, completion: @escaping (UIViewController?) -> Void) {
		if let url = self.cacheService.url(for: file.cacheKey) {
			self.viewer(for: file, url: url, completion: completion)
			return
		}

		self.filesService.downloadData(uuid: file.uid).done { data in
			if data.isEmpty {
				completion(nil)
				return
			}

			let url = self.cacheService.save(cacheKey: file.cacheKey, data: data)
			guard let url else { completion(nil); return }

			self.viewer(for: file, url: url, completion: completion)
		}.catch { error in
			completion(nil)
		}
	}

	func sharing(for file: FilesResponse.File, completion: @escaping (UIViewController?) -> Void) {
		if let url = self.cacheService.url(for: file.cacheKey) {
			let activity = self.sharingActivity(for: url)
			completion(activity)
			return
		}

		self.filesService.downloadData(uuid: file.uid).done { data in
			if data.isEmpty {
				completion(nil)
				return
			}

			let url = self.cacheService.save(cacheKey: file.cacheKey, data: data)
			guard let url else { completion(nil); return }

			let activity = self.sharingActivity(for: url)
			completion(activity)
		}.catch { error in
			completion(nil)
		}
	}

	private func sharingActivity(for url: URL) -> UIViewController {
		let activityItems = [url]

		let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
		activity.excludedActivityTypes = [.assignToContact, .postToTwitter]
		activity.completionWithItemsHandler = { _, _, _, _ in
			// do nothing
		}

		return activity
	}

	private func viewer(for file: FilesResponse.File, url: URL, completion: @escaping (UIViewController?) -> Void) {
		let contentType = ContentType(rawValue: file.contentType)
		let data = self.cacheService.data(cacheKey: file.cacheKey)

		guard let data else {
			completion(nil)
			return
		}

		switch contentType {
			case .image:
				self.queue.async {
					guard let image = UIImage(data: data) else {
						completion(nil)
						return
					}
					onMain {
						let viewController = self.imageViewer(image)
						completion(viewController)
					}
				}
			case .audio, .video:
				let viewController = self.avPlayer(url)
				completion(viewController)
			default:
				let viewController = self.documentViewer(url)
				completion(viewController)
		}
	}

	private func avPlayer(_ url: URL) -> UIViewController {
		let asset = AVURLAsset(url: url)
		let sharedPlayerItem = AVPlayerItem(asset: asset)

		self.avPlayer.player = AVPlayer(playerItem: sharedPlayerItem)
		self.avPlayer.player?.replaceCurrentItem(with: sharedPlayerItem)
		self.avPlayer.player?.playImmediately(atRate: 1.0)

		return self.avPlayer
	}

	private func imageViewer(_ image: UIImage) -> UIViewController {
		let controller = FullImageViewController()
		controller.set(image: image)
		controller.modalPresentationStyle = .overFullScreen
		controller.modalTransitionStyle = .crossDissolve

		return controller
	}

	private func documentViewer(_ url: URL) -> UIViewController {
		return DocumentPreviewController(documentURLs: [url])
	}
}
