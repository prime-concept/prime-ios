import UIKit

extension AcquaintanceView {
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

final class AcquaintanceView: UIView {
	fileprivate enum Constants {
		static let personalDataLink = "/privacy"
		static let offerLink = "/offer"
	}

	private lazy var scrollView = ScrollableStack(
		.vertical,
		arrangedSubviews: [
			.vSpacer(10),
			self.titleLabel,
			.vSpacer(30),
			self.surnameTextField,
			.vSpacer(4),
			self.nameTextField,
			.vSpacer(4),
			self.enterPhoneView,
			.vSpacer(4),
			self.emailTextField,
			.vSpacer(10),
			self.firstTermView,
			self.secondTermView,
			.vSpacer(30),
			self.nextButton,
			.vSpacer(30)
		],
		tracksKeyboard: true
	)

	private lazy var titleLabel: UILabel = {
		let label = UILabel()
		label.attributedTextThemed = Localization.localize("auth.acquaintance.title").attributed()
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
    
    private lazy var surnameTextField: EnterInfoView = {
        let view = EnterInfoView()
        view.onTextUpdate = { [weak self] isValid in
            guard let self = self else {
                return
            }
            self.isValidSurname = isValid
            self.isNextButtonEnabled = self.isValidToAuth
        }
        view.setup(with: Localization.localize("persons.edit.last.name"))
        return view
    }()
    
    private lazy var nameTextField: EnterInfoView = {
        let view = EnterInfoView()
        view.onTextUpdate = { [weak self] isValid in
            guard let self = self else {
                return
            }
            self.isValidName = isValid
            self.isNextButtonEnabled = self.isValidToAuth
        }
        view.setup(with: Localization.localize("persons.edit.first.name"))
        return view
    }()
    
    private lazy var emailTextField: EnterInfoView = {
        let view = EnterInfoView()
        view.onTextUpdate = { [weak self] isValid in
            guard let self = self else {
                return
            }
        }
        view.setup(with: Localization.localize("auth.acquaintance.email"))
        return view
    }()

	private lazy var nextButton: UIButton = {
		let button = UIButton(type: .system)

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            guard let number = self?.enterPhoneView.phoneNumber,
                  let surname = self?.surnameTextField.contentString,
                  let name = self?.nameTextField.contentString,
                  let email = self?.emailTextField.contentString else {
                return
            }
            self?.onNextButtonTap?(surname, name, number, email)
        }

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
			.foregroundColor(self.appearance.termsHyperLinkTextColor)
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
			.foregroundColor(self.appearance.termsHyperLinkTextColor)
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

    var onNextButtonTap: ((String, String, String, String) -> Void)?

	private var isValidNumber = false
	private var isValidSurname = false
	private var isValidName = false

	private var isValidToAuth: Bool {
		self.isValidNumber && self.firstTermView.isSelected && self.secondTermView.isSelected && self.isValidName && self.isValidSurname
	}

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
		_ = self.surnameTextField.infoTextField.becomeFirstResponder()
	}

	func hideKeyboard() {
		_ = self.surnameTextField.infoTextField.resignFirstResponder()
	}
}

extension AcquaintanceView: Designable {
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
		self.surnameTextField.make(.width, .equalToSuperview, -70)
		self.nameTextField.make(.width, .equalToSuperview, -70)
		self.enterPhoneView.make(.width, .equalToSuperview, -70)
		self.emailTextField.make(.width, .equalToSuperview, -70)
		self.firstTermView.make(.width, .equalToSuperview, -60)
		self.secondTermView.make(.width, .equalToSuperview, -60)
		self.nextButton.make(.size, .equal, [185, 40])
	}
}

extension AcquaintanceView {
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

