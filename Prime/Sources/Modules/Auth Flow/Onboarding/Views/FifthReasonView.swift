import UIKit

extension FifthReasonView {
    struct Appearance: Codable {
        var firstParagraphTextColor = Palette.shared.gray5
        var secondParagraphTextColor = Palette.shared.gray5
    }
}

final class FifthReasonView: UIView, ReasonView {
    private lazy var firstParagraphLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var secondParagraphLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
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
            .foregroundColor(self.appearance.secondParagraphTextColor)
            .primeFont(ofSize: 14, lineHeight: 20)
            .string()
        self.imageView.image = UIImage(named: model.image ?? "")
    }
}

extension FifthReasonView: Designable {
    func addSubviews() {
        [
            self.firstParagraphLabel,
            self.secondParagraphLabel,
            self.imageView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.firstParagraphLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
        }

        self.secondParagraphLabel.snp.makeConstraints { make in
            make.top.equalTo(self.firstParagraphLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
        }

        self.imageView.snp.makeConstraints { make in
            make.top.equalTo(self.secondParagraphLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().inset(28)
            make.height.equalTo(114)
            make.bottom.equalToSuperview()
        }
    }
}
