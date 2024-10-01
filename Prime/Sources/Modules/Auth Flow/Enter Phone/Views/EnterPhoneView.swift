import UIKit
import PhoneNumberKit

extension EnterPhoneView {
    struct Appearance: Codable {
        var separatorColor = Palette.shared.brandSecondary
        var placeholderColor = Palette.shared.gray5.withAlphaComponent(0.4)
        var tintColor = Palette.shared.brandPrimary
        var textColor = Palette.shared.gray5
        var titleTextColor = Palette.shared.brandSecondary
    }
}

final class EnterPhoneView: UIView {
    private let appearance: Appearance

    private lazy var containerView = UIView()
    var presenter: EnterPhoneViewPresenterProtocol

    private lazy var label: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = self.phoneTextField.placeholder?.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .string()
        return label
    }()

    private(set) lazy var phoneTextField: PhoneNumberTextField = {
        let textField = PhoneNumberTextField()

        textField.textColorThemed = self.appearance.textColor
        textField.tintColorThemed = self.appearance.tintColor

        textField.keyboardType = .phonePad
        textField.textContentType = .telephoneNumber

        textField.attributedPlaceholder = Localization.localize("auth.phoneNumber").attributed()
            .foregroundColor(self.appearance.placeholderColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()

        textField.fontThemed = Palette.shared.primeFont.with(size: 15)

        textField.setEventHandler(for: .editingChanged) { [weak self] in
            guard let strongSelf = self, let text = strongSelf.phoneTextField.text else {
                return
            }
            if text.isEmpty == false && text.first != "+" {
                // swiftlint:disable:next prime_font
                strongSelf.phoneTextField.text = "+\(text)"
            }

            strongSelf.updateLabel(isHidden: text.isEmpty)
            strongSelf.onTextUpdate?(textField.isValidNumber)
        }
        textField.delegate = self
        return textField
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 55)
    }

    var phoneNumber: String? {
        guard var number = self.phoneTextField.text else {
            return nil
        }

        return presenter.phoneNumber(from: number)
    }

    var onTextUpdate: ((Bool) -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        presenter = EnterPhoneViewDefaultPresenter()

        self.appearance = appearance

        super.init(frame: .zero)

        presenter = EnterPhoneViewDefaultPresenter(phoneNumberKit: phoneTextField.phoneNumberKit)

        self.addSubviews()
        self.makeConstraints()
        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        self.updateLabel(isHidden: true)
        self.phoneTextField.text?.removeAll()
    }

    private func updateLabel(isHidden: Bool) {
        guard self.label.isHidden || isHidden else {
            return
        }

        self.label.isHidden = isHidden

        self.phoneTextField.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(isHidden ? -15 : -11)
        }

        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}

extension EnterPhoneView: Designable {
    func setupView() {
        self.label.isHidden = true
    }

    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.label,
            self.phoneTextField,
            self.separatorView
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        self.label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8.5)
            make.leading.trailing.equalToSuperview()
        }

        self.phoneTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-11)
        }
    }
}

extension EnterPhoneView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
}
