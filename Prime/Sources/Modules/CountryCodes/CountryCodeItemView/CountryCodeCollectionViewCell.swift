import UIKit

final class CountryCodeCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var countryCodeItemView = CountryCodeItemView()

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
        self.addSubview(self.countryCodeItemView)
    }

    private func makeConstraints() {
        self.countryCodeItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setup(with item: CountryCode) {
        self.countryCodeItemView.setup(with: item)
    }
}
