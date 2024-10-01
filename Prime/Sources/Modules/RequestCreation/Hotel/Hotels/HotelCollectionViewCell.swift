import UIKit

final class HotelCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var hotelItemView = HotelItemView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.hotelItemView.reset()
    }

    private func addSubviews() {
        self.contentView.addSubview(self.hotelItemView)
    }

    private func makeConstraints() {
        self.hotelItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setup(with viewModel: HotelViewModel) {
        self.hotelItemView.setup(with: viewModel)
    }
}
