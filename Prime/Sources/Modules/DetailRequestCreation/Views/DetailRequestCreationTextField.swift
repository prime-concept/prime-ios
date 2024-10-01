import UIKit

extension DetailRequestCreationTextField {
    enum DetailRequestCreationTextFieldMode {
        case text(titleHidden: Bool), number, date, timeZone

        var keyboardType: UIKeyboardType {
            switch self {
            case .text, .date, .timeZone:
                return .default
            case .number:
                return .numberPad
            }
        }
    }
}

extension DetailRequestCreationTextField {
    struct Appearance: Codable {
        var skyFont = Palette.shared.primeFont.with(size: 12)
        var skyColor = Palette.shared.gray1

        var textFieldFont = Palette.shared.primeFont.with(size: 15)
        var textFieldColor = Palette.shared.mainBlack

        var backgroundColor = Palette.shared.clear

        var separatorColor = Palette.shared.gray3

        var datePickerBackgroundColor = Palette.shared.gray5

        var toolbarTintColor = Palette.shared.brandPrimary
        var toolbarItemTintColor = Palette.shared.gray5
        var toolbarItemFont = Palette.shared.primeFont.with(size: 15)
    }
}

final class DetailRequestCreationTextField: UIView, TaskFieldValueInputProtocol {
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = self.appearance.backgroundColor
        return view
    }()

    private lazy var skyLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.skyFont
        label.textColorThemed = self.appearance.skyColor
        return label
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.fontThemed = self.appearance.textFieldFont
        textField.textColorThemed = self.appearance.textFieldColor

        textField.delegate = self

        return textField
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    // MARK: - DatePicker

    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date()

        datePicker.backgroundColorThemed = Palette.shared.gray5
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.setValue(false, forKey: "highlightsToday")
			datePicker.setValue(Palette.shared.black.rawValue, forKey: "textColor")
        }
        return datePicker
    }()

    private lazy var timeZonePicker: TimeZonePickerView = {
        let picker = TimeZonePickerView(defaultTimeZone: TimeZone.current)
        return picker
    }()

    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(
            frame: CGRect(origin: .zero, size: CGSize(width: self.frame.width, height: 35))
        )

        toolbar.barTintColorThemed = self.appearance.toolbarTintColor

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
            $0.setTitleTextAttributes([.font: self.appearance.toolbarItemFont], for: .normal)
        }

        toolbar.sizeToFit()

        return toolbar
    }()

    private let appearance: Appearance
    private let type: DetailRequestCreationTextFieldMode

    private var placeholder: String? {
        didSet {
			self.textField.attributedPlaceholder = (self.placeholder ?? "")
				.attributed()
				.foregroundColor(self.appearance.textFieldColor)
				.font(self.appearance.textFieldFont)
				.string()
        }
    }

    private var text: String? {
        didSet {
            // swiftlint:disable:next prime_font
            self.textField.text = self.text
        }
    }

    var onTextEdit: ((String?) -> Void)?
    var onDateSelected: ((String) -> Void)?
    var onTimeZoneSelected: ((TimeZone) -> Void)?

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance(),
        type: DetailRequestCreationTextFieldMode = .text(titleHidden: false)
    ) {
        self.appearance = appearance
        self.type = type
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCurrentTimeZone() {
        switch self.type {
        case .timeZone:
            let defaultTimeZone = TimeZone.current
            self.setText(text: defaultTimeZone.abbreviation() ?? "", animated: true)
            self.onTimeZoneSelected?(defaultTimeZone)
        default:
            return
        }
    }

    private func setText(text: String?, animated: Bool) {
        // swiftlint:disable:next prime_font
        self.text = text
        self.updateSkyLabel(isHidden: (self.text ?? "").isEmpty, animated: animated)
    }

    private func updateSkyLabel(isHidden: Bool, animated: Bool) {
        if case .text(true) = self.type {
            return
        }

        guard self.skyLabel.isHidden || isHidden else {
            return
        }

        self.skyLabel.isHidden = isHidden
        self.textField.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.separatorView.snp.top).offset(isHidden ? -20.5 : -11.5)
        }

		self.setNeedsLayout()
		self.layoutIfNeeded()
    }

    @objc
    private func onSelectButtonTap() {
        switch self.type {
        case .timeZone:
            self.setText(
                text: self.timeZonePicker.selectedTimeZone.abbreviation() ?? "",
                animated: true
            )
            self.onTimeZoneSelected?(self.timeZonePicker.selectedTimeZone)
        default:
            let dateString = self.datePicker.date.customDateTimeString
                //FormatterHelper.formatTaskCreationDate(from: self.datePicker.date)
            self.setText(text: dateString, animated: true)
            self.onDateSelected?(dateString)
        }
        self.endEditing(true)
    }

    @objc
    private func onCancelButtonTap() {
        self.endEditing(true)
    }

    func setup(with viewModel: TaskCreationFieldViewModel) {
        switch self.type {
        case .timeZone:
            self.placeholder = Localization.localize("detailRequestCreation.timeZone")
            // swiftlint:disable:next prime_font
            self.skyLabel.text = Localization.localize("detailRequestCreation.timeZone")
        default:
            self.placeholder = viewModel.title
            // swiftlint:disable:next prime_font
            self.skyLabel.text = viewModel.title
        }

        if !viewModel.input.newValue.isEmpty {
            self.setText(text: viewModel.input.newValue, animated: false)
        }

        viewModel.onValidate = { [weak self] isValid, customMessage in
            self?.skyLabel.textColorThemed = isValid ? Palette.shared.gray1 : Palette.shared.danger
            self?.separatorView.backgroundColorThemed = isValid ? Palette.shared.gray3 : Palette.shared.danger
			self?.updateSkyLabel(isHidden: (self?.text ?? "").isEmpty && isValid, animated: true)
			
            let invalidStateTitle = customMessage ?? Localization.localize("detailRequestCreation.fillInTheField")
            // swiftlint:disable:next prime_font
			let text = isValid ? viewModel.title : invalidStateTitle
            self?.skyLabel.text = text
			self?.skyLabel.isHidden = text.isEmpty
        }
    }
}

extension DetailRequestCreationTextField: Designable {
    func setupView() {
        self.textField.keyboardType = self.type.keyboardType
        self.skyLabel.isHidden = true
    }

    func addSubviews() {
        self.addSubview(self.backgroundView)
        [self.skyLabel, self.textField, self.separatorView].forEach(self.backgroundView.addSubview)
    }

    func makeConstraints() {
		self.make(.height, .equal, 65)

        self.backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.skyLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.separatorView.snp.top).offset(-20.5)
        }
    }
}

extension DetailRequestCreationTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch self.type {
        case .date:
            textField.inputView = self.datePicker
            textField.inputAccessoryView = self.toolbar

            textField.inputView?.backgroundColorThemed = self.appearance.datePickerBackgroundColor
        case .timeZone:
            textField.inputView = self.timeZonePicker
            textField.inputAccessoryView = self.toolbar

            textField.inputView?.backgroundColorThemed = self.appearance.datePickerBackgroundColor
        default:
            break
        }
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentString = textField.text else {
            return true
        }

        defer {
            self.onTextEdit?(self.text)
        }

        let newString = (currentString as NSString).replacingCharacters(in: range, with: string)

        self.setText(text: newString, animated: true)

        return false
    }
}
