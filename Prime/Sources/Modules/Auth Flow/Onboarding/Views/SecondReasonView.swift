import UIKit

extension SecondReasonView {
    struct Appearance: Codable {
        var dotColor = Palette.shared.brandPrimary
        var dotCornerRadius: CGFloat = 4

        var bulletListStackSpacing = 20

        var firstParagraphTextColor = Palette.shared.gray5
        var subTitleTextColor = Palette.shared.gray5
        var secondParagraphTextColor = Palette.shared.gray5
        var bulletListLabelTextColor = Palette.shared.gray5
    }
}

final class SecondReasonView: UIView, ReasonView {
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

    private lazy var bulletListLabels: [UILabel] = {
        var labels: [UILabel] = []
        for _ in 0...3 {
            labels.append(UILabel())
        }
        labels.forEach { label in
            label.numberOfLines = 0
        }
        return labels
    }()

    private lazy var bulletViews: [UIView] = {
        var bulletViews: [UIView] = []
        self.bulletListLabels.forEach { label in
            let bulletView = UIView()
            let dotView = UIView()
            dotView.layer.cornerRadius = self.appearance.dotCornerRadius
            dotView.backgroundColorThemed = self.appearance.dotColor
            bulletView.addSubview(dotView)
            bulletView.addSubview(label)
            dotView.snp.makeConstraints { make in
                make.width.height.equalTo(4)
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            label.snp.makeConstraints { make in
                make.centerY.equalTo(dotView)
                make.leading.equalTo(dotView.snp.trailing).offset(10)
                make.trailing.equalToSuperview()
            }
            bulletViews.append(bulletView)
        }
        return bulletViews
    }()

    private lazy var bulletListContainerStackView: ContainerStackView = {
        let stackView = ContainerStackView()
        stackView.axis = .vertical
        stackView.spacing = self.appearance.bulletListStackSpacing
        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
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
            .foregroundColor(self.appearance.secondParagraphTextColor)
            .primeFont(ofSize: 12, lineHeight: 17)
            .string()
        for label in self.bulletListLabels.enumerated() {
            label.element.attributedTextThemed = model.dotTexts[label.offset].attributed()
                .foregroundColor(self.appearance.bulletListLabelTextColor)
                .primeFont(ofSize: 14, lineHeight: 20)
                .baselineOffset(2.0)
                .string()
        }
        self.subTitleLabel.attributedTextThemed = model.subTitle?.attributed()
            .foregroundColor(self.appearance.subTitleTextColor)
            .primeFont(ofSize: 14, weight: .medium, lineHeight: 20)
            .string()
        self.imageView.image = UIImage(named: model.image ?? "")
    }
}

extension SecondReasonView: Designable {
    func addSubviews() {
        self.bulletViews.forEach(self.bulletListContainerStackView.addView)
        [
            self.firstParagraphLabel,
            self.subTitleLabel,
            self.bulletListContainerStackView,
            self.imageView,
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

        self.bulletListContainerStackView.snp.makeConstraints { make in
            make.top.equalTo(self.subTitleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(43)
            make.trailing.equalToSuperview().inset(30)
        }

        self.imageView.snp.makeConstraints { make in
            make.top.equalTo(self.bulletListContainerStackView.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(30)
            make.trailing.equalToSuperview().inset(30)
        }

        self.secondParagraphLabel.snp.makeConstraints { make in
            make.top.equalTo(self.imageView.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(57)
            make.trailing.equalToSuperview().inset(35)
            make.bottom.equalToSuperview()
        }
    }
}

