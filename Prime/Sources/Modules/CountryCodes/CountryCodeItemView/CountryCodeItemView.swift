import UIKit

extension CountryCodeItemView {
    struct Appearance: Codable {
        var countryColor = Palette.shared.gray0
        var codeColor = Palette.shared.brandSecondary
        var separatorColor = Palette.shared.gray3
    }
}

final class CountryCodeItemView: UIView {
    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var codeLabel = UILabel()
    private lazy var countryNameLabel = UILabel()
    private let appearance: Appearance

    init(appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with item: CountryCode) {
        let weight: UIFont.Weight = item.isSelected ? .medium : .regular
        self.countryNameLabel.attributedTextThemed = item.country.attributed()
            .foregroundColor(self.appearance.countryColor)
            .primeFont(ofSize: 15, weight: weight, lineHeight: 18)
            .string()
        let code = "+\(item.code)"
        self.codeLabel.attributedTextThemed = code.attributed()
            .foregroundColor(self.appearance.codeColor)
            .primeFont(ofSize: 14, weight: weight, lineHeight: 16.8)
            .string()
    }
}

extension CountryCodeItemView: Designable {
    func setupView() {
    }

    func addSubviews() {
        [
            self.countryNameLabel,
            self.codeLabel,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.countryNameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalTo(self.codeLabel.snp.leading).inset(10)
        }

        self.codeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
