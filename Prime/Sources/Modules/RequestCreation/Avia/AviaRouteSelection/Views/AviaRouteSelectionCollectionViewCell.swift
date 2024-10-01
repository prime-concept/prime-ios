import UIKit

final class AviaRouteSelectionCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var aviaRouteSelectionItemView = AviaRouteSelectionItemView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        self.addSubview(self.aviaRouteSelectionItemView)
    }

    private func makeConstraints() {
        self.aviaRouteSelectionItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setup(with viewModel: CatalogItemRepresentable) {
        self.aviaRouteSelectionItemView.setup(with: viewModel)
    }
}
