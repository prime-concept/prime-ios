import UIKit
import MobileCoreServices
import SnapKit

@objc(ShareViewController)
class ShareViewController: UIViewController {
	private static let debugUtils = DebugUtils.shared

	private let groupName = Config.sharingGroupName 
    private let fileCoordinator = NSFileCoordinator()
    private lazy var containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.groupName)
    private lazy var logoImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "splash_logo"))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setup()

		guard let extensionItem = self.extensionContext?.inputItems.first as? NSExtensionItem,
			let itemProvider = extensionItem.attachments?.first else {
			self.closeExtension()
				return
		}
		if itemProvider.hasItemConforming(to: kUTTypeText) {
			self.handleIncomingText(itemProvider: itemProvider)
		} else if itemProvider.hasItemConforming(to: kUTTypeImage, kUTTypeMovie) {
			self.handleIncomingImage(itemProvider: extensionItem.attachments)
		} else if itemProvider.hasItemConforming(to:kUTTypeAudio) {
			self.handleIncomingAudio(itemProvider: itemProvider)
		} else if itemProvider.hasItemConforming(to: kUTTypeFileURL) {
			self.handleIncomingFile(itemProvider: extensionItem.attachments)
		} else if itemProvider.hasItemConforming(to: kUTTypeURL) {
			self.handleIncomingURL(itemProvider: itemProvider)
		} else {
			DebugUtils.shared.log(sender: self, "[Share] Error: No valid item found in extensionContext")
			self.closeExtension()
		}
    }
    
    private func setup() {
		self.view.backgroundColor = UIColor(hex: Config.splashScreenColor)
        self.view.addSubview(self.logoImageView)
        self.logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 165, height: 60))
        }
    }
    
    private func handleIncomingImage(itemProvider: [NSItemProvider]?) {
        guard let content = itemProvider else {
            return
        }
        let group = DispatchGroup()
        for attachment in content {
            group.enter()
            if attachment.hasRepresentationConforming(toTypeIdentifier: String(kUTTypeImage)) {
                self.downloadImage(attachment: attachment) { group.leave() }
            } else if attachment.hasRepresentationConforming(toTypeIdentifier: String(kUTTypeMovie)) {
                self.downloadVideo(attachment: attachment) { group.leave() }
            }
            else {
                DebugUtils.shared.log(sender: self, "[Share] Error: \(#function) unable to upload file ")
            }
            group.notify(queue: .main) {
                self.closeExtension(sharingSucceeded: true)
            }
        }
    }
    
    private func downloadImage(attachment: NSItemProvider, completion: @escaping () -> Void) {
        attachment.loadItem(forTypeIdentifier: String(kUTTypeImage), options: nil) { (item, error) in
            if let error = error {
                DebugUtils.shared.log(sender: self, "[Share] Image Download Error: \(error.localizedDescription)")
                self.closeExtension()
            }
            if let file = item, file is UIImage {
                self.saveUIImage(file: file, completion: completion)
            } else if let file = item {
                self.saveFile(file: file, completion: completion)
            }
        }
    }
    
    private func downloadVideo(attachment: NSItemProvider, completion: @escaping () -> Void) {
        attachment.loadItem(forTypeIdentifier: String(kUTTypeMovie), options: nil) { (item, error) in
            if let error = error {
                DebugUtils.shared.log(sender: self, "[Share] Video Download Error: \(error.localizedDescription)")
                self.closeExtension()
            }
            if let file = item {
                self.saveFile(file: file, completion: completion)
            }
        }
    }
    
    private func handleIncomingAudio(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: String(kUTTypeAudio), options: nil) { (item, error) in
            if let error = error {
                DebugUtils.shared.log(sender: self, "[Share] Audio Download Error: \(error.localizedDescription)")
                self.closeExtension()
            }
            if let file = item {
                self.saveFile(file: file) {
                    self.closeExtension(sharingSucceeded: true)
                }
            }
        }
    }
    
    private func handleIncomingFile(itemProvider: [NSItemProvider]?) {
        guard let content = itemProvider else { return }
        let group = DispatchGroup()
        for attachment in content {
            group.enter()
            attachment.loadItem(forTypeIdentifier: String(kUTTypeFileURL), options: nil) { (item, error) in
                if let error = error {
                    DebugUtils.shared.log(sender: self, "[Share] File Download Error: \(error.localizedDescription)")
                    self.closeExtension()
                }
                if let file = item {
                    self.saveFile(file: file) {
                        group.leave()
                    }
                }
            }
        }
        group.notify(queue: .main) {
            self.closeExtension(sharingSucceeded: true)
        }
    }
    
    private func handleIncomingURL(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil) { (item, error) in
            if let error = error {
                DebugUtils.shared.log(sender: self, "[Share] URL Download Error: \(error.localizedDescription)")
                self.closeExtension()
            }
            guard let shareUrl = item as? URL,
                  let containerURL = self.containerURL,
                  let stringData = shareUrl.absoluteString.data(using: .utf8) else {
                self.closeExtension()
                return
            }
            let directoryPath = containerURL.appendingPathComponent("files")
            let path = directoryPath.appendingPathComponent("incomeText.txt")
            var isDirectory: ObjCBool = true
            do {
                if FileManager.default.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory) {
                    try stringData.write(to: path)
                } else {
                    try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: false)
                    try stringData.write(to: path)
                }
                self.closeExtension(sharingSucceeded: true)
            } catch {
                DebugUtils.shared.log(sender: self, "[Share] error \(#function) happened while writing text file to disc: \(error).")
                self.closeExtension()
            }
        }
    }
    
    private func handleIncomingText(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: String(kUTTypeText), options: nil) { (item, error) in
            if let error = error {
                DebugUtils.shared.log(sender: self, "[Share] Text Download Error: \(error.localizedDescription)")
                self.closeExtension()
            }
            guard let text = item as? String,
                  let containerURL = self.containerURL,
                  let stringData = text.data(using: .utf8) else {
                return
            }
            let directoryPath = containerURL.appendingPathComponent("files")
            let path = directoryPath.appendingPathComponent("incomeText.txt")
            var isDirectory: ObjCBool = true
            
            do {
                if FileManager.default.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory) {
                    try stringData.write(to: path)
                } else {
                    try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: false)
                    try stringData.write(to: path)
                }
                self.closeExtension(sharingSucceeded: true)
            } catch {
                DebugUtils.shared.log(sender: self, "[Share] error \(#function) happened while writing text file to disc: \(error).")
                self.closeExtension()
            }
        }
    }
    
    private func saveUIImage(file: NSSecureCoding, completion: @escaping () -> Void) {
        guard let image = file as? UIImage, let imageData = image.pngData() else { return }
        guard let containerURL = containerURL else { return }
        var isDirectory: ObjCBool = true
        do {
            defer { completion() }

            let directoryURL = containerURL.appendingPathComponent("files")
            let fileURL = directoryURL.appendingPathComponent("image.png")
            
            let doesExists = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
            if doesExists && isDirectory.boolValue == true {
                try imageData.write(to: fileURL, options: .atomic)
                return
            }
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try imageData.write(to: fileURL, options: .atomic)
        } catch {
            DebugUtils.shared.log(sender: self, "[Share] error \(#function) happened while writing file to disc: \(error).")
            self.closeExtension()
        }
    }
    
    private func saveFile(file: NSSecureCoding, completion: @escaping () -> Void) {
        guard let url = file as? NSURL else { return }
        guard let mediaData = NSData(contentsOf: url as URL) else { return }
        guard let containerURL = self.containerURL else { return }
        var isDirectory: ObjCBool = true
        do {
            defer { completion() }

            let directoryPath = containerURL.appendingPathComponent("files")
            
            let doesExists = FileManager.default.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory)
            if doesExists && isDirectory.boolValue == true {
                try mediaData.write(to: directoryPath.appendingPathComponent(url.lastPathComponent ?? "file"), options: .atomic)
                return
            }
            try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true)
            try mediaData.write(to: directoryPath.appendingPathComponent(url.lastPathComponent ?? "file"), options: .atomic)
        } catch {
            DebugUtils.shared.log(sender: self, "[Share] error \(#function) happened while writing file to disc: \(error).")
            self.closeExtension()
        }
    }
    
    private func notifyApp() {
		guard let url = URL(string: Config.sharingDeeplink) else { return }
        let selectorOpenURL = sel_registerName("openURL:")
        var responder: UIResponder? = self
        
        while responder != nil {
            if responder?.responds(to: selectorOpenURL) == true {
                responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder?.next
        }
    }
    
    func closeExtension(sharingSucceeded: Bool = false) {
        if sharingSucceeded {
            notifyApp()
        }
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

extension NSItemProvider {
    func hasItemConforming(to identifiers: CFString...) -> Bool {
        identifiers.first{ self.hasItemConformingToTypeIdentifier($0 as String) } != nil
    }
}

extension UIColor {
	convenience init(hex: Int) {
		self.init(
			red: CGFloat((hex & 0xff0000) >> 16) / 255.0,
			green: CGFloat((hex & 0x00ff00) >> 8) / 255.0,
			blue: CGFloat(hex & 0x0000ff) / 255.0,
			alpha: CGFloat(1.0)
		)
	}
}
