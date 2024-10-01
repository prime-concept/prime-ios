import UIKit

final class AirportCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var airportItemView = AirportItemView()

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
        self.airportItemView.reset()
    }

    private func addSubviews() {
        self.contentView.addSubview(self.airportItemView)
    }

    private func makeConstraints() {
        self.airportItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setup(with viewModel: AirportViewModel) {
        self.airportItemView.setup(with: viewModel)
    }
}
