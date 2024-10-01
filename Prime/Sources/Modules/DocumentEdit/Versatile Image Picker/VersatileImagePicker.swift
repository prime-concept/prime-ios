import PhotosUI
import PromiseKit

final class VersatileImagePicker: NSObject {
    func viewController(withCamera: Bool = true) -> UIViewController {
		if #available(iOS 14, *) {
            if !withCamera {
                return self.modernPicker()
            }
		}
		return self.legacyPicker
	}

	// If nil, no thumbnails generated
	var thumbnailSmallestDimension: CGFloat?
	var onResult: (([UIImage], Error?) -> Void)?

	private var phPickerViewController: UIViewController?

	@available(iOS 14, *)
	private func modernPicker() -> PHPickerViewController {
		if let modernPicker = phPickerViewController as? PHPickerViewController {
			return modernPicker
		}

		var config = PHPickerConfiguration()
		config.selectionLimit = 0
		config.filter = .images

		let modernPicker = PHPickerViewController(configuration: config)
		modernPicker.delegate = self

		self.phPickerViewController = modernPicker

		return modernPicker
	}

	private lazy var legacyPicker: ImagePickerController = {
		let configuration = ImagePickerConfiguration()
		configuration.OKButtonTitle = "documents.photo.picker.OKButtonTitle".localized
		configuration.cancelButtonTitle = "documents.photo.picker.cancelButtonTitle".localized
		configuration.doneButtonTitle = "documents.photo.picker.doneButtonTitle".localized
		configuration.noImagesTitle = "documents.photo.picker.noImagesTitle".localized
		configuration.noCameraTitle = "documents.photo.picker.noCameraTitle".localized
		configuration.settingsTitle = "documents.photo.picker.settingsTitle".localized
		configuration.requestPermissionTitle = "documents.photo.picker.requestPermissionTitle".localized
		configuration.requestPermissionMessage = "documents.photo.picker.requestPermissionMessage".localized

		let imagePickerController = ImagePickerController(configuration: configuration)
		imagePickerController.delegate = self
		return imagePickerController
	}()

	private func complete(with images: [UIImage], error: Error?) {
		self.onResult?(images, error)
	}
}

@available(iOS 14, *)
extension VersatileImagePicker: PHPickerViewControllerDelegate {
	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            DispatchQueue.main.async {
				self.complete(with: [], error: nil)
            }
            return
        }
        var images = [UIImage]()
        for i in 0..<results.count {
            let result = results[i]
            result.itemProvider.loadObject(
                ofClass: UIImage.self,
                completionHandler: { [weak self] (object, error) in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    if i == results.count - 1 {
                        DispatchQueue.main.async {
                            self?.complete(with: images, error: error)
                        }
                    }
                }
            )
        }
	}
}

extension VersatileImagePicker: ImagePickerDelegate {
	func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
		self.complete(with: images, error: nil)
	}

	func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
		self.complete(with: images, error: nil)
	}

	func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
		self.complete(with: [], error: nil)
	}
}
