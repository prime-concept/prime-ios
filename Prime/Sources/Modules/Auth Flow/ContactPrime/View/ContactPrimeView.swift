import UIKit
import SnapKit

extension ContactPrimeView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray0
        var logoImageTintColor = Palette.shared.brandPrimary
        var closeButtonTintColor = Palette.shared.brandPrimary
        var buttonTitleColor = Palette.shared.gray5
        var gradientColors = [
			Palette.shared.gray0,
			Palette.shared.gray0
        ]
    }
}

final class ContactPrimeView: UIView {
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
		imageView.image = UIImage(named: "contact_prime_background")
		imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColorThemed = self.appearance.closeButtonTintColor
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onClose?()
        }
        return button
    }()

    private lazy var gradientView: GradientView = {
        let view = GradientView()
        view.colors = self.appearance.gradientColors
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
		label.attributedTextThemed = "contact.prime.title".brandLocalized.attributed()
            .foregroundColor(Palette.shared.gray5)
            .boldFancyFont(ofSize: 25, lineHeight: 28.75)
            .string()
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        let text = "contact.prime.phone.number.not.confirmed".localized
        label.attributedTextThemed = text.attributed()
            .foregroundColor(Palette.shared.gray5)
            .primeFont(ofSize: 14, lineHeight: 20)
            .string()
        return label
    }()

    private lazy var callButton: PrimeButton = {
        let button = PrimeButton()
        button.setAttributedTitle(
            "contact.prime.call.prime".brandLocalized.attributed()
                .foregroundColor(self.appearance.buttonTitleColor)
                .primeFont(ofSize: 14, lineHeight: 17)
                .string(),
            for: .normal
        )
		
		button.isInverted = true

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onCallButtonTap?()
        }
        return button
    }()

    private lazy var callBackButton: PrimeButton = {
        let button = PrimeButton()
        button.setAttributedTitle(
            "contact.prime.callback".localized.attributed()
                .foregroundColor(self.appearance.buttonTitleColor)
                .primeFont(ofSize: 14, lineHeight: 17)
                .string(),
            for: .normal
        )
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onCallBackButtonTap?()
        }
        return button
    }()

    private lazy var goToSiteButton: PrimeButton = {
        let button = PrimeButton()
        button.setAttributedTitle(
            "contact.prime.go.to.website".localized.attributed()
                .foregroundColor(self.appearance.buttonTitleColor)
                .primeFont(ofSize: 14, lineHeight: 17)
                .string(),
            for: .normal
        )
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onGoToSiteButtonTap?()
        }
        return button
    }()

    private lazy var buttonsStackView: ContainerStackView = {
        let view = ContainerStackView()
        view.axis = .vertical
        view.spacing = 5
        return view
    }()

    var onClose: (() -> Void)?
    var onCallButtonTap: (() -> Void)?
    var onCallBackButtonTap: (() -> Void)?
    var onGoToSiteButtonTap: (() -> Void)?

    private let appearance: Appearance

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
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

extension ContactPrimeView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        [
            self.callButton,
            self.callBackButton,
            self.goToSiteButton
        ].forEach(self.buttonsStackView.addView)

        [
            self.backgroundImageView,
            self.gradientView,
            self.closeButton,
            self.titleLabel,
            self.subTitleLabel,
            self.buttonsStackView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
		self.backgroundImageView.make(.edges, .equalToSuperview, priorities: [.defaultHigh])

        self.closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
			make.top.equalTo(self.safeAreaLayoutGuide).offset(0)
            make.leading.equalToSuperview().offset(5)
        }

        self.gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        [
            self.callButton,
            self.callBackButton,
            self.goToSiteButton
        ].forEach { $0.snp.makeConstraints { $0.height.equalTo(40) } }

		self.subTitleLabel.sizeToFit()

		self.titleLabel.snp.makeConstraints { make in
			make.leading.equalTo(self.buttonsStackView)
			make.trailing.equalToSuperview().inset(30)
			make.bottom.equalTo(self.subTitleLabel.snp.top).offset(-15)
		}

		self.subTitleLabel.snp.makeConstraints { make in
			make.leading.equalTo(self.buttonsStackView)
			make.trailing.equalToSuperview().inset(30)
			make.bottom.equalTo(self.buttonsStackView.snp.top).offset(-30)
		}

        self.buttonsStackView.snp.makeConstraints { make in
            make.height.equalTo(130)
            make.leading.trailing.equalToSuperview().inset(57)
            make.bottom.equalToSuperview().inset(59)
        }
    }
}
