import UIKit

extension ContactAdditionCodeSelectionFieldView {
    struct Appearance: Codable {
        var separatorColor = Palette.shared.gray3
        var titleTextColor = Palette.shared.gray1
        var codeTextColor = Palette.shared.gray0
    }
}

final class ContactAdditionCodeSelectionFieldView: UIView {
    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = "profile.phone.code".localized.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .string()
        return label
    }()

    private lazy var codeLabel = UILabel()
    private lazy var containerView = UIView()
    private let appearance: Appearance

    var code: String {
        self.codeLabel.text ?? ""
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 55)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with code: String) {
        self.codeLabel.attributedTextThemed = code.attributed()
            .foregroundColor(self.appearance.codeTextColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()
    }
}

extension ContactAdditionCodeSelectionFieldView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.titleLabel,
            self.codeLabel,
            self.separatorView
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        self.codeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-8.5)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.codeLabel.snp.top).offset(-2)
        }
    }
}
