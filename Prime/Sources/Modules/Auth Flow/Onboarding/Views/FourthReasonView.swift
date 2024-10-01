import UIKit

extension FourthReasonView {
    struct Appearance: Codable {
        var bulletListStackSpacing = 40
        var bulletListLabelTextColor = Palette.shared.gray5

        var dotColor = Palette.shared.brandPrimary
        var dotCornerRadius: CGFloat = 4
    }
}

final class FourthReasonView: UIView, ReasonView {
    private lazy var bulletListLabels: [UILabel] = {
        var labels: [UILabel] = []
        for _ in 0...6 {
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
                make.top.equalToSuperview().offset(5)
            }
            label.snp.makeConstraints { make in
                make.top.equalToSuperview()
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
        for label in self.bulletListLabels.enumerated() {
            label.element.attributedTextThemed = model.dotTexts[label.offset].attributed()
                .foregroundColor(self.appearance.bulletListLabelTextColor)
                .primeFont(ofSize: 14, lineHeight: 20)
                .string()
        }
    }
}

extension FourthReasonView: Designable {
    func addSubviews() {
        self.bulletViews.forEach(self.bulletListContainerStackView.addView)
        self.addSubview(self.bulletListContainerStackView)
    }

    func makeConstraints() {
        self.bulletListContainerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(43)
            make.trailing.equalToSuperview().inset(30)
        }
    }
}


