import UIKit

extension PaymentButtonsView {
    struct Appearance: Codable {
        var collectionBackgroundColor = Palette.shared.gray5
        var collectionItemSize = CGSize(width: 40, height: 36)
        var collectionMinimumInteritemSpacing: CGFloat = 5
        var collectionSectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
}

final class PaymentButtonsView: UIView {
    private lazy var collectionView = with(
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    ) { collectionView in
        let layout = UICollectionViewFlowLayout()
		layout.estimatedItemSize = self.appearance.collectionItemSize
		layout.itemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = self.appearance.collectionMinimumInteritemSpacing
        layout.minimumLineSpacing = self.appearance.collectionMinimumInteritemSpacing
        layout.sectionInset = self.appearance.collectionSectionInset
        layout.scrollDirection = .horizontal

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.dataSource = self
		collectionView.delegate = self

        collectionView.register(cellClass: HomePayItemCollectionViewCell.self)
		collectionView.register(cellClass: PromoCategoryCollectionViewCell.self)
    }

    private let appearance: Appearance
	private var promos: [PromoCategoryViewModel] = []
	private var orders: [HomePayItemViewModel] = []
	private var data: [any Equatable] = []

    var onOrderTap: ((_ index: Int) -> Void)?
	var onPromoCategoryTap: ((_ index: Int) -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	func set(orders: [HomePayItemViewModel], promoCategories promos: [PromoCategoryViewModel]) {
		if orders == self.orders, promos == self.promos {
			return
		}

		self.orders = orders
		self.promos = promos

		var newData: [any Equatable] = promos
		newData.append(contentsOf: orders)

		self.data = newData

		self.collectionView.reloadKeepingOffsetX()
    }
}

extension PaymentButtonsView: Designable {
    func addSubviews() {
        self.addSubview(self.collectionView)
    }

    func makeConstraints() {
        self.collectionView.make(.edges, .equalToSuperview)
    }
}

extension PaymentButtonsView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        self.data.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
		let dataItem = self.data[indexPath.row]
		
		if let order = dataItem as? HomePayItemViewModel {
			let cell: HomePayItemCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
			cell.setup(with: order)
			cell.addTapHandler() { [weak self] in
				self?.onOrderTap?(order.id)
			}
			return cell
		}

		if let promo = dataItem as? PromoCategoryViewModel {
			let cell: PromoCategoryCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
			cell.setup(with: promo)
			cell.addTapHandler() { [weak self] in
				self?.onPromoCategoryTap?(promo.id)
			}
			return cell
		}

        fatalError("DATA ITEM SHOULD BE HomePayItemViewModel OR PromoCategoryViewModel")
    }
}
