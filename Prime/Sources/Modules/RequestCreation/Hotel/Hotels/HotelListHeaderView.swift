import UIKit

extension HotelsListHeaderView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 12)
        var titleColor = Palette.shared.gray1

        var backgroundColor = Palette.shared.gray5
    }
}

final class HotelsListHeaderView: UICollectionReusableView, Reusable {
    private lazy var titleLabel = UILabel()
    private let appearance: Appearance

    override init(frame: CGRect = .zero) {
        self.appearance = Theme.shared.appearance()
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String) {
        self.titleLabel.attributedTextThemed = title.attributed()
            .font(self.appearance.titleFont)
            .foregroundColor(self.appearance.titleColor)
            .lineHeight(15)
            .string()
    }
}

extension HotelsListHeaderView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.addSubview(self.titleLabel)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-6)
        }
    }
}

