import UIKit

final class DocumentInfoTypeCarouselCollectionViewCell: UICollectionViewCell,
                                                        UICollectionViewDataSource,
                                                        UICollectionViewDelegate,
                                                        Reusable {
    private lazy var currentDocumentsCollectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: DocumentTypeCarouselFlowLayout())

        view.register(cellClass: DocumentTypeCollectionViewCell.self)
        view.register(cellClass: DocumentTypeAddCollectionViewCell.self)

        view.backgroundColorThemed = Palette.shared.clear
        view.showsHorizontalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .always
        return view
    }()

    private var types: [DocumentTypeCollectionViewCell.DocumentType] = []
    private var onSelect: ((Int) -> Void)?
    private var highlightPreviews = true

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.types = []
        self.currentDocumentsCollectionView.reloadData()
    }

    func configure(
        with types: [DocumentTypeCollectionViewCell.DocumentType],
        selectedIndex: Int,
        highlightPreviews: Bool = true,
        onSelect: @escaping (Int) -> Void
    ) {
        self.types = types
        self.onSelect = onSelect
        self.highlightPreviews = highlightPreviews

        (self.currentDocumentsCollectionView.collectionViewLayout as? DocumentTypeCarouselFlowLayout)?
            .selectItem(at: IndexPath(item: selectedIndex, section: 0))

        self.currentDocumentsCollectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.types.count + 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.item == self.types.count {
            let cell: DocumentTypeAddCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell
        } else if let type = self.types[safe: indexPath.item] {
            let cell: DocumentTypeCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: type)
            cell.contentView.alpha = highlightPreviews ? 1.0 : 0.1
            return cell
        }

        fatalError("Incorrect cell")
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.addTapHandler(feedback: .scale) { [weak self] in
            self?.onSelect?(indexPath.item)
            FeedbackGenerator.vibrateSelection()
        }
    }

    private func setupView() {
        self.contentView.addSubview(self.currentDocumentsCollectionView)
        self.currentDocumentsCollectionView.snp.makeConstraints { make in
            make.height.equalTo(DocumentTypeCarouselFlowLayout.height)
            make.leading.trailing.equalToSuperview()
        }

        self.currentDocumentsCollectionView.delegate = self
        self.currentDocumentsCollectionView.dataSource = self
    }
}

final class DocumentTypeCollectionViewCell: UICollectionViewCell, Reusable {
    func configure(with type: DocumentType) {
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        let view = type.imageView

        self.contentView.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.clipsToBounds = true
        view.layer.cornerRadius = 5
    }

    enum DocumentType {
        case russianPassport
        case internationalPassport
		case visa

		var imageView: UIImageView {
			let name: String
            switch self {
            case .russianPassport:
				name = "russian_passport"
            case .internationalPassport:
				name = "international_passport"
			case .visa:
				name = "document_visa"
            }

			let imageView = UIImageView(image: UIImage(named: name))
			imageView.contentMode = .scaleAspectFit

			return imageView
        }
    }
}

final class DocumentTypeCarouselFlowLayout: UICollectionViewFlowLayout {
    private static let scaleFactor: CGFloat = 1.3
    private static let interitemSpacing: CGFloat = 10
    private static let itemSize = CGSize(width: 72, height: 85)
    private static let insets = UIEdgeInsets(top: 30, left: 15, bottom: 30, right: 15)

    static let height: CGFloat = 170

    private var selectedIndexPath = IndexPath(item: 0, section: 0)
    private var attrs: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero

    override var collectionViewContentSize: CGSize {
        self.contentSize
    }

    override init() {
        super.init()

        self.scrollDirection = .horizontal
        self.minimumLineSpacing = Self.interitemSpacing
    }

    @available (*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = self.collectionView else {
            return
        }

        let itemsCount = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0) ?? 0

        var attrs: [UICollectionViewLayoutAttributes] = []
        var x: CGFloat = Self.insets.left

        for i in 0..<itemsCount {
            let isScaled = i == self.selectedIndexPath.item

            let size = CGSize(
                width: isScaled ? Self.itemSize.width * Self.scaleFactor : Self.itemSize.width,
                height: isScaled ? Self.itemSize.height * Self.scaleFactor : Self.itemSize.height
            )

            let frame = CGRect(
                x: x,
                y: Self.insets.top + (isScaled ? 0 : (Self.scaleFactor - 1) * Self.itemSize.height / 2),
                width: size.width,
                height: size.height
            )

            x += size.width + Self.interitemSpacing

            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            attr.frame = frame

            attrs.append(attr)
        }

        x -= Self.interitemSpacing
        x += Self.insets.right

        self.contentSize = CGSize(
            width: x,
            height: Self.height
        )
        self.attrs = attrs
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []

        for attr in self.attrs where attr.frame.intersects(rect) {
            attributes.append(attr)
        }

        return attributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.attrs.first(where: { $0.indexPath == indexPath })
    }

    func selectItem(at indexPath: IndexPath) {
        guard indexPath != self.selectedIndexPath else {
            return
        }

        self.selectedIndexPath = indexPath
        self.invalidateLayout()
    }
}
