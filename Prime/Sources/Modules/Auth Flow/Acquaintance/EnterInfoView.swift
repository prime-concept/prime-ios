import UIKit
import PhoneNumberKit

extension EnterInfoView {
    struct Appearance: Codable {
        var separatorColor = Palette.shared.brandSecondary
        var placeholderColor = Palette.shared.gray5.withAlphaComponent(0.4)
        var tintColor = Palette.shared.brandPrimary
        var textColor = Palette.shared.gray5
        var titleTextColor = Palette.shared.brandSecondary
    }
}

final class EnterInfoView: UIView {
    private let appearance: Appearance

    private lazy var containerView = UIView()

    private lazy var label = UILabel()
    
    private(set) lazy var infoTextField: UITextField = {
        let textField = UITextField()

        textField.textColorThemed = self.appearance.textColor
        textField.tintColorThemed = self.appearance.tintColor

        textField.attributedPlaceholder = Localization.localize("auth.phoneNumber").attributed()
            .foregroundColor(self.appearance.placeholderColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()

        textField.fontThemed = Palette.shared.primeFont.with(size: 15)

        textField.setEventHandler(for: .editingChanged) { [weak self] in
            guard let strongSelf = self, let text = strongSelf.infoTextField.text else {
                return
            }
            strongSelf.updateLabel(isHidden: text.isEmpty)
            strongSelf.onTextUpdate?(!text.isEmpty)
        }
        textField.delegate = self

        return textField
    }()

    var contentString: String? {
        guard var text = self.infoTextField.text else {
            return nil
        }
        return text
    }

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 55)
    }

    var onTextUpdate: ((Bool) -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)

        self.addSubviews()
        self.makeConstraints()
        self.setupView()
    }
    
    func setup(with placeholderText: String) {
        self.infoTextField.attributedPlaceholder = placeholderText.attributed()
            .foregroundColor(self.appearance.placeholderColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()
        self.label.attributedTextThemed = placeholderText.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .string()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        self.updateLabel(isHidden: true)
        self.infoTextField.text?.removeAll()
    }

    private func updateLabel(isHidden: Bool) {
        guard self.label.isHidden || isHidden else {
            return
        }

        self.label.isHidden = isHidden

        self.infoTextField.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(isHidden ? -15 : -11)
        }

        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}

extension EnterInfoView: Designable {
    func setupView() {
        self.label.isHidden = true
    }

    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.label,
            self.infoTextField,
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

        self.infoTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-11)
        }
    }
}

extension EnterInfoView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
}
