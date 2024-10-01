import QuickLook

final class DocumentPreviewController: QLPreviewController {
    private var documentURLs: [URL] = []

	init(documentURLs: [URL], needsCloseButton: Bool = false) {
        self.documentURLs = documentURLs
        super.init(nibName: nil, bundle: nil)

        self.dataSource = self

		if needsCloseButton {
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(
				title: "common.close".localized,
				style: .plain,
				target: self,
				action: #selector(self.dismissButtonTapped)
			)
		}
    }

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = .white
	}

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    @objc
    private func dismissButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - QLPreviewControllerDataSource

extension DocumentPreviewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.documentURLs.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let documentURL = self.documentURLs[safe: index] else {
            fatalError("URL must exists")
        }

        return documentURL as QLPreviewItem
    }
}
