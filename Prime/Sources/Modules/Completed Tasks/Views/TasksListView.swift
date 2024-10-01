import UIKit

extension TasksListView {
    struct Appearance: Codable {
		var headerHeight: CGFloat = 36
        var collectionMinimumLineSpacing: CGFloat = 0
        var collectionBackgroundColor = Palette.shared.gray5
		var collectionInset: UIEdgeInsets = .zero
    }
}

final class TasksListView: UIView {
	private lazy var headerView = TasksListHeaderView {
		$0.translatesAutoresizingMaskIntoConstraints = false
	}

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = self.appearance.collectionMinimumLineSpacing
        layout.minimumLineSpacing = self.appearance.collectionMinimumLineSpacing
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.contentInset = self.appearance.collectionInset

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(cellClass: TasksListItemCollectionViewCell.self)

        return collectionView
    }()

    private let appearance: Appearance

    private var data = [CompletedTaskViewModel]()

    var onSelectTaskByTaskId: ((Int) -> Void)?
	var onSelectTaskType: ((TaskTypeEnumeration) -> Void)? {
		didSet {
			self.headerView.onSelectTaskType = self.onSelectTaskType
		}
	}

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

    func update(viewModel: CompletedTasksListViewModel) {
        self.data = viewModel.completedTaskViewModels
		self.headerView.set(data: viewModel.headerItemViewModels)
        self.collectionView.reloadData()
    }
}

extension TasksListView: Designable {
    func addSubviews() {
		self.addSubview(self.headerView)
        self.addSubview(self.collectionView)
    }

    func makeConstraints() {
		self.headerView.make(.edges(except: .bottom), .equalToSuperview)
		self.headerView.make(.height, .equal, self.appearance.headerHeight)
		self.collectionView.make(.edges(except: .top), .equalToSuperview)
		self.collectionView.make(.top, .equal, to: .bottom, of: self.headerView, +10)
    }
}

extension TasksListView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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
        let cell: TasksListItemCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.setup(with: self.data[indexPath.row])

        // Фикс релейаута ячеек при появлении на скролле
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
		let taskId = self.data[indexPath.row].task.taskID
        cell.addTapHandler { [weak self] in self?.onSelectTaskByTaskId?(taskId) }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.removeTapHandler()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let viewModel = self.data[safe: indexPath.row] else {
            return .zero
        }

		let reference = TasksListItemCollectionViewCell.reference
		reference.setup(with: viewModel)

		let width = collectionView.bounds.width
		let height = reference.sizeFor(width: width).height

        return CGSize(width: width, height: height)
    }
}
