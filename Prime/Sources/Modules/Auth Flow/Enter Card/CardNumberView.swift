import Foundation
import UIKit
import SnapKit
import JMMaskTextField_Swift

extension CardNumberView {
    struct Appearance: Codable {
        var titleColor = Palette.shared.gray5
        var nextButtonEnabledColor = Palette.shared.gray5
        var nextButtonDisabledColor = Palette.shared.gray1

        var placeholderColor = Palette.shared.gray5.withAlphaComponent(0.6)
        var textColor = Palette.shared.gray5
        var tintColor = Palette.shared.brandPrimary
        var backgroundColor = Palette.shared.gray0
    }
}

struct CardNumberErrorViewModel {
	let errorText: String
}

extension CardNumberErrorViewModel {
	static func make(from error: Error) -> CardNumberErrorViewModel {
		let description = error.descriptionLowercased
		if description.contains("404") {
			return CardNumberErrorViewModel(
				errorText: "card.verification.error".brandLocalized
			)
		}
		return CardNumberErrorViewModel(
			errorText: "contact.we.will.call.you.back.error.message".localized
		)
	}
}

final class CardNumberView: UIView {
    private lazy var cardContainerView = UIView()
    private lazy var cardTextField: JMMaskTextField = {
        let textField = JMMaskTextField()
        textField.keyboardType = .numberPad
        textField.textColorThemed = self.appearance.textColor
        textField.tintColorThemed = self.appearance.tintColor
       
        textField.keyboardType = .phonePad
        textField.textContentType = .creditCardNumber
        textField.maskString = "000 000 000"
        textField.attributedPlaceholder = "000 000 000".attributed()
            .foregroundColor(self.appearance.placeholderColor)
            .font(UIFont(name: "CourierNewPSMT", size: 28)!)
            .lineHeight(32)
            .string()
        textField.font = UIFont(name: "CourierNewPSMT", size: 28)
        textField.delegate = self
        return textField
    }()
    
    private lazy var cardBackgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "auth_card")
        return imageView
    }()
    
    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedTextThemed = "card.verification.info".brandLocalized.attributed()
            .foregroundColor(self.appearance.titleColor)
            .primeFont(ofSize: 15, weight: .regular, lineHeight: 18)
            .lineBreakMode(.byWordWrapping)
            .alignment(.center)
            .string()
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isHidden = true
        return label
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
		button.setTitle("auth.next".localized, for: .normal)

		button.titleLabel?.fontThemed = Palette.shared.primeFont.with(size: 14)
		button.setTitleColor(self.appearance.nextButtonEnabledColor, for: .normal)
		button.setTitleColor(self.appearance.nextButtonDisabledColor, for: .disabled)

        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0.5
        button.layer.borderColorThemed = self.appearance.nextButtonDisabledColor

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            guard let number = self?.cardTextField.unmaskedText else {
                return
            }
            self?.onNextButtonTap?(number)
        }

        return button
    }()
    
    private let appearance: Appearance
    
    private var isNextButtonEnabled: Bool = false {
        didSet {
			let isEnabled = isNextButtonEnabled
            self.nextButton.isEnabled = isEnabled

			self.nextButton.layer.borderColorThemed = isEnabled
				? self.appearance.nextButtonEnabledColor
				: self.appearance.nextButtonDisabledColor
        }
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

    func showKeyboard() {
        _ = self.cardTextField.becomeFirstResponder()
    }

    func hideKeyboard() {
        _ = self.cardTextField.resignFirstResponder()
    }

    func showErrorAlert(with model: CardNumberErrorViewModel) {
        self.errorLabel.isHidden = false
        self.cardTextField.textColorThemed = self.appearance.tintColor
        self.makeErrorValue(model.errorText)
    }

    private func makeErrorValue(_ text: String) {
        self.errorLabel.attributedTextThemed = text.attributed()
            .foregroundColor(self.appearance.tintColor)
            .primeFont(ofSize: 12, weight: .regular, lineHeight: 12)
            .lineBreakMode(.byWordWrapping)
            .alignment(.center)
            .string()
    }
    
    func hideErrorAlert() {
        self.errorLabel.isHidden = true
        self.cardTextField.textColorThemed = self.appearance.textColor
    }
}

extension CardNumberView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.isNextButtonEnabled = false
    }
    
    func addSubviews() {
        [
            self.cardBackgroundImage,
            self.cardTextField
        ].forEach(self.cardContainerView.addSubview)

        [
            self.cardContainerView,
            self.infoLabel,
            self.nextButton,
            self.errorLabel
        ].forEach(self.addSubview)
    }
    
    func makeConstraints() {
		self.cardBackgroundImage.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}

        self.cardTextField.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(70)
            make.leading.equalToSuperview().inset(20)
        }
        
        self.cardContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(40)
            make.height.equalTo(self.cardContainerView.snp.width).multipliedBy(0.62)
        }
        
        self.infoLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(55)
            make.top.equalTo(self.cardContainerView.snp.bottom).offset(20)
        }
        
        self.nextButton.snp.makeConstraints { make in
            make.top.equalTo(self.infoLabel.snp.bottom).offset(30)
            make.size.equalTo(CGSize(width: 185, height: 40))
            make.centerX.equalToSuperview()
        }
        
        self.errorLabel.snp.makeConstraints { make in
            make.top.equalTo(self.nextButton.snp.bottom).offset(10)
			make.bottom.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
    }
}

extension CardNumberView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let text = textField.text as NSString? else { return true }
        let newText = text.replacingCharacters(in: range, with: string)
        if newText.count >= 11 {
            self.isNextButtonEnabled = true
        } else {
            self.isNextButtonEnabled = false
            self.hideErrorAlert()
        }
        return true
    }
}
