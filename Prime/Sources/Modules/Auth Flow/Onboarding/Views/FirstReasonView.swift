import UIKit

protocol ReasonView where Self: UIView {
    func configure(with model: OnboardingTextContentViewModel)
}

extension FirstReasonView {
    struct Appearance: Codable {
        var firstParagraphTextColor = Palette.shared.gray5
        var subTitleTextColor = Palette.shared.gray5
        var secondParapgraphTextColor = Palette.shared.gray5
    }
}

final class FirstReasonView: UIView, ReasonView {
    private lazy var firstParagraphLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var secondParagraphLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let appearance: Appearance

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: OnboardingTextContentViewModel) {
        self.firstParagraphLabel.attributedTextThemed = model.firstParagraph?.attributed()
            .foregroundColor(self.appearance.firstParagraphTextColor)
            .primeFont(ofSize: 14, lineHeight: 20)
            .string()
        self.secondParagraphLabel.attributedTextThemed = model.secondParagraph?.attributed()
            .foregroundColor(self.appearance.secondParapgraphTextColor)
            .primeFont(ofSize: 14, lineHeight: 20)
            .string()
        self.subTitleLabel.attributedTextThemed = model.subTitle?.attributed()
            .foregroundColor(self.appearance.subTitleTextColor)
            .primeFont(ofSize: 14, weight: .medium, lineHeight: 20)
            .string()
    }
}

extension FirstReasonView: Designable {
    func addSubviews() {
        [
            self.firstParagraphLabel,
            self.subTitleLabel,
            self.secondParagraphLabel
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.firstParagraphLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
        }

        self.subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.firstParagraphLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
        }

        self.secondParagraphLabel.snp.makeConstraints { make in
            make.top.equalTo(self.subTitleLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
            make.bottom.equalToSuperview()
        }
    }
}
