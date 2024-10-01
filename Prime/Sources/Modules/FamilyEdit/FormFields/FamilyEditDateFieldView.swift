import UIKit

struct FamilyEditDatePickerModel {
    let title: String
    let placeholder: String
    let value: String
    let onSelect: (Date) -> Void
}

extension FamilyEditDateFieldView {
    struct Appearance: Codable {
        var neutralSeparatorColor = Palette.shared.gray3
        var activeSeparatorColor = Palette.shared.gray0
        var textColor = Palette.shared.gray0
        var titleTextColor = Palette.shared.gray1
    }
}

class FamilyEditDateFieldView: UIView {
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        let minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: Date())
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
    private lazy var titleLabel = UILabel()
    private lazy var textField = UITextField()

    private var model: FamilyEditDatePickerModel?
    private var onDateSelected: ((Date) -> Void)?

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.neutralSeparatorColor
        return view
    }()

    private lazy var containerView = UIView()
    private let appearance: Appearance


    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with viewModel: FamilyEditDatePickerModel) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(viewModel.title)
        self.textField.attributedPlaceholder = Self.makePlaceholder(viewModel.placeholder)
        self.textField.attributedTextThemed = Self.makeValue(viewModel.value)
        
        self.textField.inputView = self.datePicker
        self.textField.inputAccessoryView = self.toolbar
        self.textField.inputView?.backgroundColorThemed = Palette.shared.gray5
        self.textField.tintColorThemed = Palette.shared.clear
        self.onDateSelected = viewModel.onSelect
        self.containerView.addTapHandler { [weak self] in
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
}

extension FamilyEditDateFieldView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.titleLabel,
            self.textField,
            self.separatorView
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.textField.snp.top).offset(-2)
        }

        self.textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-10)
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
