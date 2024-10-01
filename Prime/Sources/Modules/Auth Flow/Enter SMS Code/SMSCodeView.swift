import UIKit

extension SMSCodeView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray0
        var labelTextColor = Palette.shared.brandSecondary
        var labelWrongStateTextColor = Palette.shared.danger

        var titleColor = Palette.shared.gray5

        var codeFont = Palette.shared.primeFont.with(size: 15)
        var codePlaceholderColor = Palette.shared.gray5.withAlphaComponent(0.4)
        var codeTextColor = Palette.shared.gray5
        var codeTintColor = Palette.shared.brandPrimary

        var separatorColor = Palette.shared.brandSecondary
        var separatorWrongStateColor = Palette.shared.danger

        var nextButtonTitleColor = Palette.shared.gray5
        var nextButtonBorderColor = Palette.shared.brandSecondary

        var receiveButtonTitleColor = Palette.shared.brandSecondary
        var receiveButtonDisabledTitleColor = Palette.shared.gray5.withAlphaComponent(0.4)
        var receveButtonDisabledTimerColor = Palette.shared.gray5
		var receiveButtonUnderlineColor = Palette.shared.gray5.withAlphaComponent(0.15)

		var loginProblemsButtonTitleColor = Palette.shared.gray5.withAlphaComponent(0.5)
    }
}

final class SMSCodeView: UIView {
    private lazy var codeContainerView = UIView()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = self.codeTextField.placeholder?.attributed()
            .foregroundColor(self.appearance.labelTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .string()
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
		label.numberOfLines = 0
        label.attributedTextThemed = Localization.localize("auth.verificationTitle").attributed()
            .foregroundColor(self.appearance.titleColor)
            .primeFont(ofSize: 20, weight: .bold, lineHeight: 24)
			.lineBreakMode(.byWordWrapping)
            .alignment(.center)
            .string()
		label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var codeTextField: UITextField = {
        let textField = UITextField()

        textField.fontThemed = self.appearance.codeFont

        textField.attributedPlaceholder = Localization.localize("auth.codeFromSMS").attributed()
            .foregroundColor(self.appearance.codePlaceholderColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()

        textField.textColorThemed = self.appearance.codeTextColor
        textField.tintColorThemed = self.appearance.codeTintColor

        textField.keyboardType = .numberPad
        textField.textContentType = .oneTimeCode

        textField.setEventHandler(for: .editingChanged) { [weak self] in
			textField.updateKeepingCursor {
				self?.didEditCodeTextField()
			}
        }
        return textField
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var receiveCodeButton: UIButton = {
        let button = UIButton(type: .system)

        button.setAttributedTitle(
            Localization.localize("auth.retry").attributed()
                .foregroundColor(self.appearance.receiveButtonTitleColor)
                .primeFont(ofSize: 14, lineHeight: 16)
                .string(),
            for: .normal
        )

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onReceiveCodeButtonTap?()
        }

        return button
    }()

	private lazy var loginProblemsButton: UIButton = {
		let button = UIButton(type: .system)

		button.setAttributedTitle(
			Localization.localize("auth.problems").attributed()
				.foregroundColor(self.appearance.loginProblemsButtonTitleColor)
				.primeFont(ofSize: 14, lineHeight: 16)
				.lineBreakMode(.byTruncatingTail)
				.string(),
			for: .normal
		)

		button.setEventHandler(for: .touchUpInside) { [weak self] in
			self?.onLoginProblemsButtonTap?()
		}

		return button
	}()

    private let appearance: Appearance
    private let smsCodeLength = 4

    // MARK: - Button action closures

    var onSMSCodeEntered: ((String) -> Void)?
    var onReceiveCodeButtonTap: (() -> Void)?
	var onLoginProblemsButtonTap: (() -> Void)?

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

    func startTimer() {
        self.receiveCodeButton.isUserInteractionEnabled = false

        self.codeTextField.text?.removeAll()
        self.updateLabel(isHidden: true)
    }

    func stopTimer() {
        let attributedReceiveCodeButtonTitle = Localization.localize("auth.retry").attributed()
            .foregroundColor(self.appearance.receiveButtonTitleColor)
            .primeFont(ofSize: 14, lineHeight: 16)
            .string()
        self.receiveCodeButton.setAttributedTitle(attributedReceiveCodeButtonTitle, for: .normal)
        self.receiveCodeButton.isUserInteractionEnabled = true

        self.setInitialState()
    }

    func updateTimer(tick: Int) {
        let title = (Localization.localize("auth.retryTimer") + " ").attributed()
            .foregroundColor(self.appearance.receiveButtonDisabledTitleColor)
            .primeFont(ofSize: 14, lineHeight: 16)
            .string()

        let timer = "\(tick)".attributed()
            .foregroundColor(self.appearance.receveButtonDisabledTimerColor)
            .primeFont(ofSize: 14, lineHeight: 16)
            .string()

        UIView.performWithoutAnimation {
            self.receiveCodeButton.setAttributedTitle(title + timer, for: .normal)
            self.receiveCodeButton.layoutIfNeeded()
        }
    }

    func showKeyboard() {
        self.codeTextField.becomeFirstResponder()
    }

	func hideKeyboard() {
		self.codeTextField.resignFirstResponder()
	}

    func setWrongState() {
        self.label.textColorThemed = self.appearance.labelWrongStateTextColor
        self.separatorView.backgroundColorThemed = self.appearance.separatorWrongStateColor
    }

    // MARK: - Private

    private func didEditCodeTextField() {
        guard var text = self.codeTextField.text else {
            return
        }

		self.updateLabel(isHidden: text.isEmpty)

        if text.count > self.smsCodeLength {
            self.codeTextField.text?.removeLast()
			text = String(text.prefix(self.smsCodeLength))
        }

		if text.count == self.smsCodeLength {
			self.onSMSCodeEntered?(text)
		}
    }

    private func updateLabel(isHidden: Bool) {
        guard self.label.isHidden || isHidden else {
            return
        }

        self.label.isHidden = isHidden

        self.codeTextField.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(isHidden ? -15 : -11)
        }

        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    private func setInitialState() {
        self.label.textColorThemed = self.appearance.labelTextColor
        self.separatorView.backgroundColorThemed = self.appearance.separatorColor
    }
}

extension SMSCodeView: Designable {
    func setupView() {
        self.label.isHidden = true
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.addSubview(self.codeContainerView)
        [
            self.label,
            self.codeTextField,
            self.separatorView
        ].forEach(self.codeContainerView.addSubview)
		
        [
            self.titleLabel,
            self.codeContainerView,
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
			make.top.equalTo(self.safeAreaLayoutGuide).offset(44)
            make.leading.equalToSuperview().offset(30)
			make.trailing.equalToSuperview().offset(-30).priority(999)
        }

        self.codeContainerView.snp.makeConstraints { make in
            make.height.equalTo(55)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(30)
            make.leading.lessThanOrEqualToSuperview().offset(30)
            make.trailing.equalToSuperview().offset(-30).priority(999)
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        self.label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8.5)
            make.leading.trailing.equalToSuperview()
        }

        self.codeTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-11)
        }

		let buttonsHStack = UIStackView(.horizontal)
		buttonsHStack.addArrangedSubviews(
			self.receiveCodeButton,
			.hSpacer(growable: 10),
			self.loginProblemsButton
		)

		self.addSubview(buttonsHStack)

		buttonsHStack.make(.top, .equal, to: .bottom, of: self.codeContainerView, +24)
		buttonsHStack.make(.hEdges, .equalToSuperview, [30, -30], priorities: [.defaultHigh])
		buttonsHStack.make(.height, .equal, 40)

		let receiveCodeUnderlineView = UIView()
		receiveCodeUnderlineView.backgroundColorThemed = self.appearance.receiveButtonUnderlineColor
		receiveCodeUnderlineView.make(.height, .equal, 1)
		self.addSubview(receiveCodeUnderlineView)
		receiveCodeUnderlineView.make(.hEdges, .equal, to: self.receiveCodeButton.titleLabel)
		receiveCodeUnderlineView.make(.top, .equal, to: .bottom, of: self.receiveCodeButton.titleLabel, +3)
    }
}
