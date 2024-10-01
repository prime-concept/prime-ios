import UIKit

extension HomeHeaderView {
    struct Appearance: Codable {
        var profileTintColor = Palette.shared.brandSecondary
        var searchTintColor = Palette.shared.brandSecondary

        var collectionBackgroundColor = Palette.shared.clear
        var collectionItemSize = CGSize(width: 109, height: 32)
        var collectionMinimumInteritemSpacing: CGFloat = 4

        var gradientColors = [
			Palette.shared.gray4.withAlphaComponent(0),
            Palette.shared.gray4
        ]
    }
}

final class HomeHeaderView: UIView {
    private lazy var profileButton: UIButton = {
        let button = UIButton()
        button.setImage(
            UIImage(named: "profile_icon")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
		button.imageEdgeInsets.left = 14
		button.imageEdgeInsets.right = 5
        button.tintColorThemed = self.appearance.profileTintColor
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onTapProfile?()
        }
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.appearance.collectionItemSize
        layout.minimumInteritemSpacing = self.appearance.collectionMinimumInteritemSpacing
        layout.minimumLineSpacing = self.appearance.collectionMinimumInteritemSpacing
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(cellClass: HomePayItemCollectionViewCell.self)

        return collectionView
    }()

    private lazy var gradientView: GradientView = {
        let view = GradientView()
        view.colors = self.appearance.gradientColors.map { $0 }
        view.isHorizontal = true
        return view
    }()

    private let appearance: Appearance
    private var data: [HomePayItemViewModel] = []

    var onOrderTap: ((_ orderID: Int) -> Void)?
    var onTapProfile: (() -> Void)?

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

    func set(data: [HomePayItemViewModel]) {
        self.data = data
        self.collectionView.reloadData()
    }
}

extension HomeHeaderView: Designable {
    func addSubviews() {
        [self.profileButton, self.collectionView, self.gradientView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.profileButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.size.equalTo(CGSize(width: 49, height: 46))
        }

        self.collectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.equalTo(self.profileButton.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(-15)
        }

        self.gradientView.snp.makeConstraints { make in
            make.trailing.equalTo(self.collectionView)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(17)
        }
    }
}

extension HomeHeaderView: UICollectionViewDataSource, UICollectionViewDelegate {
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
        let cell: HomePayItemCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.setup(with: self.data[indexPath.row])
        return cell
    }

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let orderID = self.data[indexPath.row].id
		self.onOrderTap?(orderID)
	}
}

