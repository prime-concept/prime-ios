import UIKit

extension PhoneNumberView {
    struct Appearance: Codable {
        var titleColor = Palette.shared.gray5
        var nextButtonTitleColor = Palette.shared.gray5
        var nextButtonBorderColor = Palette.shared.brandSecondary

        var termsTextColor = Palette.shared.gray5
        var termsHyperLinkTextColor = Palette.shared.brandSecondary
        var termsBackgroundColor = Palette.shared.clear
		var backgroundColor = Palette.shared.gray0
    }
}

final class PhoneNumberView: UIView {
    fileprivate enum Constants {
        static let personalDataLink = "/privacy"
        static let offerLink = "/offer"
    }

	private lazy var scrollView = ScrollableStack(
		.vertical,
		arrangedSubviews:
			[.vSpacer(44),
			 self.titleLabel,
			 .vSpacer(30),
			 self.enterPhoneView,
			 .vSpacer(10),
			 self.firstTermView,
			 self.secondTermView,
			 .vSpacer(30),
			 self.nextButton,
			 .vSpacer(30)],
		tracksKeyboard: true
	)

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("auth.title").attributed()
            .foregroundColor(self.appearance.titleColor)
            .primeFont(ofSize: 20, weight: .bold, lineHeight: 24)
            .alignment(.center)
            .string()
        return label
    }()

    private lazy var enterPhoneView: EnterPhoneView = {
        let view = EnterPhoneView()
        view.onTextUpdate = { [weak self] isValid in
            guard let self = self else {
                return
            }
            self.isValidNumber = isValid
            self.isNextButtonEnabled = self.isValidToAuth
        }
        return view
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)

        button.setAttributedTitle(
            Localization.localize("auth.next").attributed()
                .foregroundColor(self.appearance.nextButtonTitleColor)
                .primeFont(ofSize: 14, lineHeight: 17)
                .string(),
            for: .normal
        )

        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0.5
        button.layer.borderColorThemed = self.appearance.nextButtonBorderColor

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            guard let number = self?.enterPhoneView.phoneNumber else {
                return
            }
            self?.onNextButtonTap?(number)
        }

        return button
    }()

    private lazy var firstTermView = with(TermView()) { view in
        let consentText = Localization.localize("auth.terms.consent")
        let personalDataText = Localization.localize("auth.terms.personal.data")

        let attributedConsentText = consentText.attributed()
            .foregroundColor(self.appearance.termsTextColor)
            .primeFont(ofSize: 12, lineHeight: 12)
            .string()
        let attributedPersonalDataText = personalDataText.attributed()
            .primeFont(ofSize: 12, lineHeight: 12)
            .hyperLink(Constants.personalDataLink)
            .string()

		view.onLinkTap = { _ in
			self.presentPrivacyPolicyViewController()
		}

        view.setupTerms(with: attributedConsentText + attributedPersonalDataText)
    }

    private lazy var secondTermView = with(TermView()) { view in
        let readText = Localization.localize("auth.terms.confirm")
        let offerText = Localization.localize("auth.terms.offer")

        let attributedReadText = readText.attributed()
            .foregroundColor(self.appearance.termsTextColor)
            .primeFont(ofSize: 12, lineHeight: 12)
            .string()
        let attributedOfferText = offerText.attributed()
            .primeFont(ofSize: 12, lineHeight: 12)
            .foregroundColor(self.appearance.termsTextColor)
            .hyperLink(Constants.offerLink)
            .string()

		view.onLinkTap = { _ in
			self.presentTermsViewController()
		}

        view.setupTerms(with: attributedReadText + attributedOfferText)
    }

    private let appearance: Appearance

    private var isNextButtonEnabled: Bool = false {
        didSet {
            self.nextButton.alpha = self.isNextButtonEnabled ? 1.0 : 0.5
            self.nextButton.isEnabled = self.isNextButtonEnabled
        }
    }

    // MARK: - Button action closures

    private var isValidNumber = false

    private var isValidToAuth: Bool {
        self.isValidNumber && self.firstTermView.isSelected && self.secondTermView.isSelected
    }

    var onNextButtonTap: ((String) -> Void)?

    init(appearance: Appearance = Theme.shared.appearance()) {
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

    func reset() {
        self.enterPhoneView.reset()
    }

	func showKeyboard() {
		_ = self.enterPhoneView.phoneTextField.becomeFirstResponder()
	}

	func hideKeyboard() {
		_ = self.enterPhoneView.phoneTextField.resignFirstResponder()
	}
}

extension PhoneNumberView: Designable {
    func setupView() {
        [
            self.firstTermView,
            self.secondTermView
        ].forEach { view in
            view.onCheckBoxTap = { [weak self] in
                guard let self = self else {
                    return
                }
                self.isNextButtonEnabled = self.isValidToAuth
            }
        }
		self.backgroundColorThemed = self.appearance.backgroundColor
        self.isNextButtonEnabled = false
    }

    func addSubviews() {
        self.addSubview(self.scrollView)
    }

    func makeConstraints() {
		self.scrollView.make(.edges, .equalToSuperview)
		self.scrollView.stackView.alignment = .center

		self.titleLabel.make(.width, .equalToSuperview, -60)
		self.enterPhoneView.make(.width, .equalToSuperview, -70)
		self.firstTermView.make(.width, .equalToSuperview, -60)
		self.secondTermView.make(.width, .equalToSuperview, -60)
		self.nextButton.make(.size, .equal, [185, 40])
    }
}

extension PhoneNumberView {
	private func present(_ viewController: UIViewController) {
		let router = ModalRouter(
			source: self.viewController,
			destination: viewController,
			modalPresentationStyle: .pageSheet
		)
		router.route()
	}

	private func presentPrivacyPolicyViewController() {
		let viewController = LegalInfoViewController(pdfContent: UIImage(named: Config.privacyPolicyImageName))
		self.present(viewController)
	}

	private func presentTermsViewController() {
		let viewController = LegalInfoViewController(pdfContent: UIImage(named: Config.termsOfUseImageName))
		self.present(viewController)
	}
}
