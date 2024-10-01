import UIKit

final class HotelCityCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var hotelCityItemView = HotelCityItemView()

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
        self.hotelCityItemView.reset()
    }

    private func addSubviews() {
        self.contentView.addSubview(self.hotelCityItemView)
    }

    private func makeConstraints() {
        self.hotelCityItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setup(with viewModel: HotelCityViewModel) {
        self.hotelCityItemView.setup(with: viewModel)
    }
}
