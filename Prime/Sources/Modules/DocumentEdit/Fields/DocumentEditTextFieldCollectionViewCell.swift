import UIKit

struct DocumentEditTextFieldModel {
    let title: String
    let placeholder: String
    let value: String
    let fieldType: FieldType
    let onUpdate: (String) -> Void

    enum FieldType {
        case text
        case familyName
        case middleName
        case givenName
        case number

        var keyboardType: UIKeyboardType {
            switch self {
            case .text:
                return .default
            case .familyName, .middleName, .givenName:
                return .namePhonePad
            case .number:
                return .numbersAndPunctuation
            }
        }

        var contentType: UITextContentType? {
            switch self {
            case .text, .number:
                return nil
            case .familyName:
                return .familyName
            case .middleName:
                return .middleName
            case .givenName:
                return .givenName
            }
        }

		var autocapitalizationType: UITextAutocapitalizationType {
			switch self {
			case .text, .number:
				return .sentences
			default:
				return .words
			}
		}
    }
}

struct DocumentEditDatePickerModel {
    let title: String
    let placeholder: String
    let value: String
    let onSelect: (Date) -> Void
}

struct DocumentEditCountryPickerModel {
    let title: String
    let placeholder: String
    let value: String
    let pickerInvoker: () -> Void
}

final class DocumentEditTextFieldCollectionViewCell: UICollectionViewCell, Reusable, UITextFieldDelegate {
    private lazy var titleLabel = UILabel()
    private lazy var textField = UITextField()
    private lazy var separatorView = OnePixelHeightView()

    private var model: DocumentEditTextFieldModel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.titleLabel.attributedTextThemed = nil
        self.textField.attributedTextThemed = nil
		self.contentView.removeTapHandler()
    }

    func configure(with model: DocumentEditTextFieldModel) {
        self.model = model

        self.titleLabel.attributedTextThemed = Self.makeTitle(model.title)
        self.textField.attributedPlaceholder = Self.makePlaceholder(model.placeholder)
        self.textField.attributedTextThemed = Self.makeValue(model.value)

        self.textField.keyboardType = model.fieldType.keyboardType
        self.textField.textContentType = model.fieldType.contentType
		self.textField.autocapitalizationType = model.fieldType.autocapitalizationType
        self.textField.setEventHandler(for: .editingChanged) { [weak self] in
            self?.textField.text.flatMap { text in
                model.onUpdate(text)
				self?.textField.updateKeepingCursor {
					self?.textField.attributedTextThemed = Self.makeValue(text)
				}
            }
        }
    }

    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, lineHeight: 15)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }

    private static func makePlaceholder(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0.withAlphaComponent(0.3))
            .string()
    }

    private static func makeValue(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }

    private func setupView() {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textField)
        self.contentView.addSubview(self.separatorView)

        self.titleLabel.numberOfLines = 1

        self.textField.delegate = self
        self.textField.tintColorThemed = Palette.shared.gray0

        self.separatorView.backgroundColorThemed = Palette.shared.gray3

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.textField.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(21)
        }

        self.separatorView.snp.makeConstraints { make in
            make.top.equalTo(self.textField.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(15)
			make.bottom.equalToSuperview()
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25) {
            self.separatorView.backgroundColorThemed = Palette.shared.gray0
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25) {
            self.separatorView.backgroundColorThemed = Palette.shared.gray3
        }
    }
}
