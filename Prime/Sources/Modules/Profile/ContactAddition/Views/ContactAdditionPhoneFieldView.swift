import PhoneNumberKit
import UIKit

extension ContactAdditionPhoneFieldView {
    struct Appearance: Codable {
        var neutralSeparatorColor = Palette.shared.gray3
        var activeSeparatorColor = Palette.shared.gray0
        var textColor = Palette.shared.gray0
        var titleTextColor = Palette.shared.gray1
    }
}

class ContactAdditionPhoneFieldView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = self.phoneTextField.placeholder?.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .string()
        return label
    }()

    private lazy var codeSelectionView: ContactAdditionCodeSelectionFieldView = {
        let view = ContactAdditionCodeSelectionFieldView()
        view.addTapHandler { [weak self] in
            self?.onTapCodeSelection?()
        }
        return view
    }()

    private lazy var phoneTextField: ContactAdditionPhoneNumberTextField = {
        let textField = ContactAdditionPhoneNumberTextField()
        let placeholder = "profile.phone".localized + "*"
        textField.textColorThemed = self.appearance.textColor
        textField.keyboardType = .phonePad
        textField.textContentType = .telephoneNumber
        textField.attributedPlaceholder = placeholder.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()
        textField.fontThemed = Palette.shared.primeFont.with(size: 15)
        textField.setEventHandler(for: .editingChanged) { [weak self] in
            guard let self = self,
                  let phoneNumber = self.phoneTextField.text else {
                return
            }
            self.handleChange(of: phoneNumber)
        }
        return textField
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.neutralSeparatorColor
        return view
    }()

    private lazy var containerView = UIView()
    private lazy var phoneNumberKit = PhoneNumberKit()
    private let appearance: Appearance
    var onPhoneTextUpdate: ((String) -> Void)?
    var onTapCodeSelection: (() -> Void)?

    var phoneNumber: String {
        self.codeSelectionView.code + (self.phoneTextField.text ?? "")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 55)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
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

    func setup(with viewModel: ContactAdditionPhoneFieldViewModel?) {
        self.codeSelectionView.setup(with: viewModel?.code ?? "+7")
        self.phoneTextField.attributedTextThemed = (viewModel?.number ?? "").attributed()
            .foregroundColor(self.appearance.textColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()
        self.updateLabel(isHidden: viewModel?.number.isEmpty ?? true)
    }

    func set(code: String) {
        self.codeSelectionView.setup(with: code)
        guard let phoneNumber = self.phoneTextField.text else {
            return
        }
        self.handleChange(of: phoneNumber)
    }

    // MARK: - Helpers

    private func updateLabel(isHidden: Bool) {
        guard self.titleLabel.isHidden || isHidden else {
            return
        }

        self.titleLabel.isHidden = isHidden
        self.phoneTextField.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(isHidden ? -15 : -11)
        }
    }

    private func handleChange(of phoneNumber: String) {
        let code = self.codeSelectionView.code.replacingOccurrences(of: "+", with: "")
        guard let countryCode = UInt64(code),
              let defaultRegion = self.phoneNumberKit.mainCountry(forCode: countryCode) else {
            return
        }
        let formatter = PartialFormatter(
            phoneNumberKit: self.phoneNumberKit,
            defaultRegion: defaultRegion,
            withPrefix: false
        )
        self.phoneTextField.attributedTextThemed = formatter.formatPartial(phoneNumber).attributed()
            .foregroundColor(self.appearance.textColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()
        self.updateLabel(isHidden: phoneNumber.isEmpty)
        self.onPhoneTextUpdate?(self.codeSelectionView.code + phoneNumber)
    }
}

extension ContactAdditionPhoneFieldView: Designable {
    func setupView() {
        self.titleLabel.isHidden = true
    }

    func addSubviews() {
        self.addSubview(self.codeSelectionView)
        self.addSubview(self.containerView)
        [
            self.titleLabel,
            self.phoneTextField,
            self.separatorView
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.codeSelectionView.snp.makeConstraints { make in
            make.width.equalTo(65)
            make.leading.equalToSuperview().offset(15)
            make.top.bottom.equalToSuperview()
        }

        self.containerView.snp.makeConstraints { make in
            make.leading.equalTo(self.codeSelectionView.snp.trailing).offset(20)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8.5)
            make.leading.trailing.equalToSuperview()
        }

        self.phoneTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-11)
        }
    }
}
