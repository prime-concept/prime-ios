import UIKit

final class DocumentEditAttachmentsCollectionViewCell: UICollectionViewCell,
                                                       UICollectionViewDataSource,
                                                       UICollectionViewDelegate,
                                                       Reusable {
    private lazy var attachmentsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 75, height: 75)
        layout.minimumLineSpacing = 10
        layout.scrollDirection = .horizontal

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.contentInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)

        view.register(cellClass: DocumentEditAttachmentsAddCollectionViewCell.self)
        view.register(cellClass: DocumentEditAttachmentCollectionViewCell.self)

        view.backgroundColorThemed = Palette.shared.clear
        view.showsHorizontalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .always
        return view
    }()

    private var attachments: [DocumentEditAttachmentModel] = []
    private var onAdd: (() -> Void)?
	
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with attachments: [DocumentEditAttachmentModel], onAdd: @escaping () -> Void) {
        self.attachments = attachments
        self.onAdd = onAdd
        self.attachmentsCollectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.attachments.count + 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell: DocumentEditAttachmentsAddCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell
        } else if let attachment = self.attachments[safe: indexPath.item - 1] {
            let cell: DocumentEditAttachmentCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: attachment)
            return cell
        }

        fatalError("Incorrect cell")
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if indexPath.item == 0 {
            cell.addTapHandler(feedback: .scale) { [weak self] in
                self?.onAdd?()
                FeedbackGenerator.vibrateSelection()
            }
        }
    }

    private func setupView() {
        self.contentView.addSubview(self.attachmentsCollectionView)
        self.attachmentsCollectionView.snp.makeConstraints { make in
            make.height.equalTo(105)
            make.edges.equalToSuperview()
        }

        self.attachmentsCollectionView.delegate = self
        self.attachmentsCollectionView.dataSource = self
    }
}
