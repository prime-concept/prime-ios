import UIKit

extension OnboardingStarContentView {
    struct Appearance: Codable {
        var buttonBorderWidth: CGFloat = 0.5
        var buttonCornerRadius: CGFloat = 22
        var buttonBorderColor = Palette.shared.brandSecondary
        var buttonTintColor = Palette.shared.brandSecondary
        var diagonalViewColor = Palette.shared.brown
        var buttonsStackViewSpacing: CGFloat = 9
        var titleTextColor = Palette.shared.gray5
        var firstParagraphTextColor = Palette.shared.gray5
        var secondParagraphTextColor = Palette.shared.gray5
    }
}

final class OnboardingStarContentView: UIView {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var diagonalView: DiagonalView = {
        let view = DiagonalView()
        view.backgroundColorThemed = self.appearance.diagonalViewColor
        return view
    }()

    private lazy var starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

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

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.telegramButton])
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillEqually
        stackView.spacing = self.appearance.buttonsStackViewSpacing
        return stackView
    }()

	private lazy var telegramButton = with(UIButton(type: .system)) { button in
		button.tintColorThemed = self.appearance.buttonTintColor
		button.setImage(UIImage(named: "telegram-icon"), for: .normal)
		button.setEventHandler(for: .touchUpInside) {
			if let url = URL(string: "https://t.me/prime_art_of_life"),
			   UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url)
                AnalyticsEvents.Onboarding.switchedToTelegram.send()
			}
		}
	}

    lazy var contentView = UIView()

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

    override func layoutSubviews() {
        super.layoutSubviews()
        self.drawDiagonalView()
    }

    func configure(with model: OnboardingStarContentViewModel) {
        self.titleLabel.attributedTextThemed = model.title.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .boldFancyFont(ofSize: 25, lineHeight: 28.75)
            .string()
        self.firstParagraphLabel.attributedTextThemed = model.firstParagraph.attributed()
            .foregroundColor(self.appearance.firstParagraphTextColor)
            .primeFont(ofSize: 14, lineHeight: 20)
            .string()
        self.secondParagraphLabel.attributedTextThemed = model.secondParagraph?.attributed()
            .foregroundColor(self.appearance.secondParagraphTextColor)
            .primeFont(ofSize: 14, lineHeight: 20)
            .string()
        self.starImageView.image = UIImage(named: model.image)
    }

    // MARK: - Helpers

    private func drawDiagonalView() {
        let layerHeight = self.diagonalView.layer.frame.height
        let layerWidth = self.diagonalView.layer.frame.width
        self.diagonalView.points = [
            CGPoint(x: 0, y: layerHeight),
            CGPoint(x: layerWidth, y: layerHeight),
            CGPoint(x: layerWidth, y: layerHeight * 1 / 3),
            CGPoint(x: 0, y: layerHeight * 2 / 3)
        ]
    }
}

extension OnboardingStarContentView: Designable {
    func addSubviews() {
        [
            self.starImageView,
            self.diagonalView
        ].forEach(self.addSubview)
        [
            self.titleLabel,
            self.firstParagraphLabel,
            self.secondParagraphLabel,
            self.buttonsStackView
        ].forEach(self.scrollView.addSubview)
        self.addSubview(self.scrollView)
    }

    func makeConstraints() {
        self.diagonalView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.starImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(30)
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(70)
            make.bottom.equalTo(self.snp.centerY).offset(100)
        }

        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.snp.centerY)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().inset(170)
            make.trailing.equalToSuperview().inset(20)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(self).offset(57)
            make.trailing.equalTo(self).inset(30)
        }

        self.firstParagraphLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(15)
            make.leading.equalTo(self).offset(57)
            make.trailing.equalTo(self).inset(30)
        }

        self.secondParagraphLabel.snp.makeConstraints { make in
            make.top.equalTo(self.firstParagraphLabel.snp.bottom).offset(20)
            make.leading.equalTo(self).offset(57)
            make.trailing.equalTo(self).inset(30)
        }

		self.telegramButton.snp.makeConstraints { make in
			make.width.height.equalTo(44)
		}

        self.buttonsStackView.snp.makeConstraints { make in
            make.top.equalTo(self.secondParagraphLabel.snp.bottom).offset(15)
            make.height.equalTo(44)
            make.leading.equalTo(self).offset(57)
            make.bottom.equalToSuperview()
        }
    }
}
