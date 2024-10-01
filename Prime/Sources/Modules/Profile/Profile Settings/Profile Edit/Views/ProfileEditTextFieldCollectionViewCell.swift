import UIKit

final class ProfileEditTextFieldCollectionViewCell: UICollectionViewCell, Reusable, UITextFieldDelegate {
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
		let minimumDate = Date() + (-100).years
        let maximumDate = Date()
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate

        datePicker.backgroundColorThemed = Palette.shared.gray5
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.setValue(false, forKey: "highlightsToday")
			datePicker.setValue(Palette.shared.black.rawValue, forKey: "textColor")
        }
        return datePicker
    }()

    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(
            frame: CGRect(origin: .zero, size: CGSize(width: self.frame.width, height: 35))
        )

        toolbar.barTintColorThemed = Palette.shared.brandPrimary

        let doneAction = UIBarButtonItem(
            title: Localization.localize("detailRequestCreation.select"),
            style: .plain,
            target: self,
            action: #selector(self.onSelectButtonTap)
        )

        let spaceButton = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let cancelAction = UIBarButtonItem(
            title: Localization.localize("detailRequestCreation.cancel"),
            style: .plain,
            target: self,
            action: #selector(self.onCancelButtonTap)
        )

        toolbar.items = [cancelAction, spaceButton, doneAction]
        toolbar.items?.forEach {
			$0.tintColor = Palette.shared.gray5.rawValue
            $0.setTitleTextAttributes([.font: Palette.shared.primeFont.with(size: 15)], for: .normal)
        }

        toolbar.sizeToFit()

        return toolbar
    }()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "arrow_right"))
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        view.tintColorThemed = Config.isPersonalDataEditingAvailable ? Palette.shared.gray1 : Palette.shared.clear
        return view
    }()

    private lazy var titleLabel = UILabel()
    private lazy var textField = UITextField()
    private lazy var separatorView = OnePixelHeightView()

    private var model: ProfileEditTextFieldModel?
    private var onDateSelected: ((Date) -> Void)?

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
    }

    func configure(with model: ProfileEditTextFieldModel) {
        self.model = model

        self.titleLabel.attributedTextThemed = Self.makeTitle(model.title)
        self.textField.attributedPlaceholder = Self.makePlaceholder(model.placeholder)
        self.textField.attributedTextThemed = Self.makeValue(model.value)

        self.textField.keyboardType = model.fieldType.keyboardType
        self.textField.textContentType = model.fieldType.contentType
        self.arrowView.isHidden = true
        self.textField.setEventHandler(for: .editingChanged) { [weak self] in
            self?.textField.text.flatMap { text in
                model.onUpdate(text)
				self?.textField.updateKeepingCursor {
					self?.textField.attributedTextThemed = Self.makeValue(text)
				}
            }
        }
    }

    func configure(with model: ProfileEditDatePickerModel) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(model.title)
        self.textField.attributedPlaceholder = Self.makePlaceholder(model.placeholder)
        self.textField.attributedTextThemed = Self.makeValue(model.value)

        self.textField.inputView = self.datePicker
        self.textField.inputAccessoryView = self.toolbar
        self.textField.inputView?.backgroundColorThemed = Palette.shared.gray5
        self.textField.tintColorThemed = Palette.shared.clear
        self.arrowView.isHidden = false
        self.onDateSelected = model.onSelect
        self.contentView.addTapHandler { [weak self] in
            self?.textField.becomeFirstResponder()
        }
    }

    @objc
    private func onSelectButtonTap() {
        let dateString = self.datePicker.date.birthdayString
        self.textField.attributedTextThemed = Self.makeValue(dateString)
        self.onDateSelected?(self.datePicker.date)
        self.endEditing(true)
    }

    @objc
    private func onCancelButtonTap() {
        self.endEditing(true)
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
            .foregroundColor(Config.isPersonalDataEditingAvailable ? Palette.shared.gray0 : Palette.shared.gray1)
            .string()
    }

    private func setupView() {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textField)
        self.contentView.addSubview(self.separatorView)
        self.contentView.addSubview(self.arrowView)

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

        self.arrowView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
            make.size.equalTo(CGSize(width: 16, height: 10))
        }

        self.separatorView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(self.textField.snp.bottom).offset(10)
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
