import UIKit

extension TasksListHeaderView {
    struct Appearance: Codable {
        var collectionBackgroundColor = Palette.shared.gray5
        var collectionItemHeight: CGFloat = 36
        var collectionMinimumInteritemSpacing: CGFloat = 4
        var collectionItemTitleFont = Palette.shared.primeFont.with(size: 12, weight: .medium)
        var collectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        var collectionItemWidthPadding: CGFloat = 21

        var gradientColors = [
			Palette.shared.gray4.withAlphaComponent(0),
            Palette.shared.gray4
        ]
    }
}

final class TasksListHeaderView: UICollectionReusableView, Reusable {
    static let height: CGFloat = 36

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = self.appearance.collectionMinimumInteritemSpacing
        layout.minimumLineSpacing = self.appearance.collectionMinimumInteritemSpacing
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.contentInset = self.appearance.collectionInset
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(cellClass: TasksListHeaderViewCell.self)

        return collectionView
    }()

    private lazy var gradientView: GradientView = {
        let view = GradientView()
        view.colors = self.appearance.gradientColors.map { $0 }
        view.isHorizontal = true
        return view
    }()

    private let appearance: Appearance
    private var data: [CompletedTasksListHeaderItemViewModel] = []
    var onSelectTaskType: ((TaskTypeEnumeration) -> Void)?

    override init(frame: CGRect) {
        self.appearance = Theme.shared.appearance()
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(data: [CompletedTasksListHeaderItemViewModel]) {
        self.data = data
        self.collectionView.reloadData()
    }
}

extension TasksListHeaderView: Designable {
    func addSubviews() {
        [self.collectionView, self.gradientView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.gradientView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(17)
        }
    }
}

extension TasksListHeaderView: UICollectionViewDataSource, UICollectionViewDelegate {
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
        let cell: TasksListHeaderViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.setup(with: self.data[indexPath.row])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.addTapHandler { [weak self] in
            guard let self = self else {
                return
            }
            self.onSelectTaskType?(self.data[indexPath.row].type)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.removeTapHandler()
    }
}

extension TasksListHeaderView: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let viewModel = self.data[safe: indexPath.row] else {
            return .zero
        }
		let referenceCell = TasksListHeaderViewCell.reference
		referenceCell.setup(with: viewModel)

		let cellHeight = self.appearance.collectionItemHeight
		var cellWidth = referenceCell.sizeFor(height: cellHeight).width
		cellWidth += self.appearance.collectionItemWidthPadding

        return CGSize(width: cellWidth, height: cellHeight)
    }
}
