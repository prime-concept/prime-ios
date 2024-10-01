import UIKit

extension ThirdReasonView {
    struct Appearance: Codable {
        var firstParagraphTextColor = Palette.shared.gray5
    }
}

final class ThirdReasonView: UIView, ReasonView {
    private lazy var firstParagraphLabel: UILabel = {
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
        self.imageView.image = UIImage(named: model.image ?? "")
    }
}

extension ThirdReasonView: Designable {
    func addSubviews() {
        [
            self.firstParagraphLabel,
            self.imageView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.firstParagraphLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(30)
        }

        self.imageView.snp.makeConstraints { make in
            make.top.equalTo(self.firstParagraphLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(57)
            make.bottom.equalToSuperview()
        }
    }
}

