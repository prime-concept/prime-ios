import UIKit

extension AirportListHeaderView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 12)
        var titleColor = Palette.shared.gray1
    }
}

final class AirportListHeaderView: UIView {
    private let appearance: Appearance

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.titleFont
        label.textColorThemed = self.appearance.titleColor
        return label
    }()

    var title: String = "" {
        didSet {
            // swiftlint:disable:next prime_font
            self.titleLabel.text = title
        }
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AirportListHeaderView: Designable {
    func addSubviews() {
        [
            self.titleLabel
        ]
        .forEach(addSubview)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-4)
        }
    }
}

