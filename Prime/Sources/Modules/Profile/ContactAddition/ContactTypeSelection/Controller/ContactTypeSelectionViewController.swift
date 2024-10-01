import UIKit

extension ContactTypeSelectionViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var collectionBackgroundColor = Palette.shared.clear
        var collectionItemSize = CGSize(width: UIScreen.main.bounds.width, height: 55)
        var grabberViewBackgroundColor = Palette.shared.gray3
        var grabberCornerRadius: CGFloat = 2
    }
}

final class ContactTypeSelectionViewController: UIViewController {
    private lazy var grabberView: UIView = {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 36, height: 3))
        }
        view.layer.cornerRadius = self.appearance.grabberCornerRadius
        view.backgroundColorThemed = self.appearance.grabberViewBackgroundColor
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.appearance.collectionItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellClass: ContactTypeSelectionCollectionViewCell.self)
        return collectionView
    }()

    private var data: [ContactTypeViewModel]
    private let appearance: Appearance
    private let onSelect: (ContactTypeViewModel) -> Void

    var scrollView: UIScrollView? {
        self.collectionView
    }

    init(
        with data: [ContactTypeViewModel],
        appearance: Appearance = Theme.shared.appearance(),
        onSelect: @escaping (ContactTypeViewModel) -> Void
    ) {
        self.data = data
        self.appearance = appearance
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }

    // MARK: - Private

    private func setupView() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor
        [
            self.grabberView,
            self.collectionView
        ].forEach(view.addSubview)

        self.grabberView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
            make.centerX.equalToSuperview()
        }

        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.grabberView.snp.bottom).offset(17)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

extension ContactTypeSelectionViewController: UICollectionViewDataSource {
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
        let cell: ContactTypeSelectionCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.setup(with: self.data[indexPath.row])
        return cell
    }
}

extension ContactTypeSelectionViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let item = self.data[indexPath.row]
        cell.addTapHandler { [weak self] in
            self?.onSelect(item)
            self?.dismiss(animated: true)
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
