import UIKit
import PromiseKit

struct DocumentEditAttachmentModel {
    var uuid: String?
    let original: UIImage
	let thumbnail: UIImage?
    var isDeleted: Bool = false
    let onDelete: () -> Void
	let onSelect: () -> Void
}

final class DocumentEditAttachmentCollectionViewCell: UICollectionViewCell, Reusable {
	private static var thumbnailsCache = NSCache<UIImage, UIImage>()
	private static let thumbnailsQueue = DispatchQueue(
		label: "ru.com.technolab.prime.DocumentEditAttachmentCollectionViewCell.thumbnails",
		qos: .userInteractive,
		attributes: .concurrent
	)

	private var currentImage: UIImage?
	private var onSelect: (() -> Void)?

    private lazy var deleteButton: UIView = {
        let view = UIView()
        view.backgroundColorThemed = Palette.shared.gray5
        view.dropShadow(
            offset: CGSize(width: 0, height: 5),
            radius: 5,
            color: Palette.shared.black,
			opacity: 0.08
        )
        view.layer.cornerRadius = 16

        let iconImageView = UIImageView(image: UIImage(named: "document_remove"))
        iconImageView.tintColorThemed = Palette.shared.brandPrimary

        view.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
            make.center.equalToSuperview()
        }

        view.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

		self.contentView.addSubview(view)
		view.snp.makeConstraints { make in
			make.right.bottom.equalToSuperview().offset(4)
		}

        return view
    }()

	private lazy var imageView: UIImageView = {
		let imageView = UIImageView()
		imageView.contentMode = .scaleAspectFill

		self.contentView.addSubview(imageView)
		imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = 10
		imageView.layer.borderWidth = 1
		imageView.layer.borderColorThemed = Palette.shared.gray0.withAlphaComponent(0.1)

		imageView.isUserInteractionEnabled = true
		imageView.addTapHandler { [weak self] in
			self?.onSelect?()
		}

		return imageView
	}()

    func configure(with attachment: DocumentEditAttachmentModel) {
		self.showThumbnail(from: attachment)
		self.deleteButton.addTapHandler(feedback: .scale, attachment.onDelete)
		self.contentView.bringSubviewToFront(self.deleteButton)
    }

	func showThumbnail(from viewModel: DocumentEditAttachmentModel) {
		let image = viewModel.original
		self.currentImage = image
		self.onSelect = viewModel.onSelect

		self.imageView.image = nil

		if let thumbnail = viewModel.thumbnail {
			self.imageView.image = thumbnail
			return
		}

		self.imageView.showSimplestLoader()

		Self.thumbnailsQueue.promise {
			Guarantee<UIImage> { seal in
				let thumbnail = Self.thumbnailsCache.object(forKey: image) ??
								image.resize(smallestDimesion: 75)
				seal(thumbnail)
			}
		}
		.done(on: .main) { [weak self] thumbnail in
			guard self?.currentImage == image else {
				return
			}
            Self.thumbnailsCache.removeObject(forKey: image)
			Self.thumbnailsCache.setObject(thumbnail, forKey: image)
			self?.imageView.image = thumbnail
			self?.imageView.hideSimplestLoader()
		}
		.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) thumbnail generation failed",
					parameters: error.asDictionary
				)
		}
	}

	deinit {
		self.currentImage.some {
			Self.thumbnailsCache.removeObject(forKey: $0)
		}
	}
}
