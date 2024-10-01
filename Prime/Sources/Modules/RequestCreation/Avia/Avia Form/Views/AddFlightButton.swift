import UIKit

extension AddFlightButton {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var titleTextColor = Palette.shared.brandSecondary
        var tintColor = Palette.shared.brandSecondary
    }
}

final class AddFlightButton: UIView {
    private lazy var addImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "avia_plus"))
        view.tintColorThemed = self.appearance.tintColor
        return view
    }()

    private lazy var titleLabel = UILabel()

    private let appearance: Appearance

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 39)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
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
}

extension AddFlightButton: Designable {
    func setupView() {
        self.titleLabel.attributedTextThemed = "avia.add.another.flight".localized.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 13, lineHeight: 16)
            .string()
        self.titleLabel.numberOfLines = 1
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        [
            self.addImageView,
            self.titleLabel
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.addImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalTo(self.titleLabel)
            make.leading.equalToSuperview().offset(10)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(self.addImageView.snp.trailing).offset(5)
            make.trailing.equalToSuperview().inset(10)
        }
    }
}

