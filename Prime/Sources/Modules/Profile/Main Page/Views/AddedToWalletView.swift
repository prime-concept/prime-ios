import UIKit

extension AddedToWalletView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.black
        var cornerRadius: CGFloat = 8
        var borderWidth: CGFloat = 1
        var borderColor = Palette.shared.gray1
        var textColor = Palette.shared.gray5
    }
}

final class AddedToWalletView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = "profile.card.addedToWallet".localized.attributed()
            .foregroundColor(self.appearance.textColor)
            .font(.systemFont(ofSize: 6, weight: .semibold))
            .lineHeight(7.2)
            .alignment(.left)
            .string()
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = "Apple Wallet".attributed()
            .foregroundColor(self.appearance.textColor)
            .font(.systemFont(ofSize: 12, weight: .semibold))
            .lineHeight(14.4)
            .alignment(.left)
            .string()
        return label
    }()

    private lazy var walletImageView = UIImageView(image: .init(named: "apple_wallet"))
    private let appearance: Appearance

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AddedToWalletView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.layer.cornerRadius = self.appearance.cornerRadius
        self.layer.borderColorThemed = self.appearance.borderColor
        self.layer.borderWidth = self.appearance.borderWidth
    }

    func addSubviews() {
        [
            self.walletImageView,
            self.titleLabel,
            self.subtitleLabel
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.walletImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.walletImageView.snp.trailing).offset(7)
            make.trailing.equalToSuperview().offset(-5)
            make.top.equalTo(self.walletImageView)
        }

        self.subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.walletImageView.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(-5)
            make.bottom.equalTo(self.walletImageView)
        }
    }
}
