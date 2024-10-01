import UIKit

extension AviaRouteSelectionViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var collectionBackgroundColor = Palette.shared.clear
        var collectionItemSize = CGSize(width: UIScreen.main.bounds.width, height: 55)
        var collectionHeaderReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 20)
        var grabberViewBackgroundColor = Palette.shared.gray3
        var grabberCornerRadius: CGFloat = 2
    }
}

protocol AviaRouteSelectionViewControllerProtocol: AnyObject {
    func reload()
}

final class AviaRouteSelectionViewController: UIViewController {
    private lazy var grabberView = with(UIView()) { view in
        view.layer.cornerRadius = self.appearance.grabberCornerRadius
        view.backgroundColorThemed = self.appearance.grabberViewBackgroundColor
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.appearance.collectionItemSize
        layout.headerReferenceSize = self.appearance.collectionHeaderReferenceSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellClass: AviaRouteSelectionCollectionViewCell.self)
        collectionView.register(
            viewClass: AirportListHeaderReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
        return collectionView
    }()

    private let appearance: Appearance
    private let presenter: AviaRouteSelectionPresenterProtocol

    init(
        presenter: AviaRouteSelectionPresenterProtocol,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.presenter.didLoad()
    }

    // MARK: - Private

    private func setupView() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor
        [
            self.grabberView,
            self.collectionView
        ].forEach(view.addSubview)

        self.grabberView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 35, height: 3))
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

extension AviaRouteSelectionViewController: AviaRouteSelectionViewControllerProtocol {
    func reload() {
        self.collectionView.reloadData()
    }
}

extension AviaRouteSelectionViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        self.presenter.numberOfItems()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell: AviaRouteSelectionCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.setup(with: self.presenter.item(at: indexPath.row))
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let view: AirportListHeaderReusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            for: indexPath
        )
        view.title = self.presenter.title
        return view
    }
}

extension AviaRouteSelectionViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.addTapHandler { [weak self] in
            self?.presenter.select(at: indexPath.row)
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
