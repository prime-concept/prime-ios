import UIKit

final class HomePayItemCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var itemView = HomePayItemView()

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
        self.contentView.addSubview(self.itemView)
    }

    private func makeConstraints() {
        self.itemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setup(with viewModel: HomePayItemViewModel) {
        self.itemView.setup(with: viewModel)
    }
}
