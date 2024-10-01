import UIKit
import ChatSDK

extension ContactAdditionView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var deleteBackgroundColor = Palette.shared.clear
        var deleteBorderWidth: CGFloat = 0.5
        var deleteBorderColor = Palette.shared.gray3
        var deleteTextColor = Palette.shared.danger
        var saveBackgroundColor = Palette.shared.brandPrimary
        var buttonCornerRadius: CGFloat = 8
        var grabberViewBackgroundColor = Palette.shared.gray3
        var grabberCornerRadius: CGFloat = 2
        var addTextColor = Palette.shared.gray5
        var changeDataTextColor = Palette.shared.gray2
    }
}

final class ContactAdditionView: UIView {
    private lazy var grabberView: UIView = {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 36, height: 3))
        }
        view.layer.cornerRadius = self.appearance.grabberCornerRadius
        view.backgroundColorThemed = self.appearance.grabberViewBackgroundColor
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    private lazy var buttonsStackView: UIStackView = {
		let stackView = UIStackView(arrangedSubviews: [self.deleteButton, self.saveButton])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 5
		stackView.isHidden = true
        return stackView
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        let title = Localization.localize("profile.delete").attributed()
            .foregroundColor(self.appearance.deleteTextColor)
			.primeFont(ofSize: 16, lineHeight: 18)
            .string()
        button.setAttributedTitle(title, for: .normal)
        button.backgroundColorThemed = self.appearance.deleteBackgroundColor
        button.layer.borderWidth = self.appearance.deleteBorderWidth
        button.layer.borderColorThemed = self.appearance.deleteBorderColor
        button.layer.cornerRadius = self.appearance.buttonCornerRadius
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onDelete?()
        }
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColorThemed = self.appearance.saveBackgroundColor
        button.layer.cornerRadius = self.appearance.buttonCornerRadius
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onSave?()
        }
        return button
    }()

    private lazy var scrollView = UIScrollView()
    private let appearance: Appearance
    private var output: ContactAdditionViewModel?
    private var keyboardHeightTracker: KeyboardHeightTracker?

    private lazy var chagneDataLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedTextThemed = "profile.changeInfo.title".brandLocalized.attributed()
            .foregroundColor(self.appearance.changeDataTextColor)
			.primeFont(ofSize: 16, lineHeight: 18)
            .lineBreakMode(.byWordWrapping)
            .alignment(.center)
            .string()
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    var onTapCodeSelection: (() -> Void)?
    var onTapSelection: ((ContactAdditionFieldType) -> Void)?
    var onTextUpdate: ((ContactAdditionFieldType, String) -> Void)?
    var onSave: (() -> Void)?
    var onDelete: (() -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
        self.listenToKeyboard()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ContactAdditionViewModel) {
        self.output = viewModel
        switch viewModel.type {
        case .phone:
            let phoneFieldView = ContactAdditionPhoneFieldView()
            phoneFieldView.setup(with: viewModel.phoneViewModel)
            phoneFieldView.onTapCodeSelection = { [weak self] in
                self?.onTapCodeSelection?()
            }
            phoneFieldView.onPhoneTextUpdate = { [weak self] text in
                self?.onTextUpdate?(.phone, text)
            }
            self.stackView.addArrangedSubview(phoneFieldView)
        case .email:
            let emailFieldView = ContactAdditionFieldView()
            emailFieldView.setup(with: viewModel.additionFieldViewModel(for: .email))
            emailFieldView.onTextUpdate = { [weak self] text in
                self?.onTextUpdate?(.email, text)
            }
            self.stackView.addArrangedSubview(emailFieldView)
        case .address:
            let fieldsStackView = UIStackView()
            fieldsStackView.axis = .vertical

            let types: [ContactAdditionFieldType] = [.country, .city, .street, .house, .apartment]

            for type in types {
                let fieldView = ContactAdditionFieldView()
                fieldView.setup(with: viewModel.additionFieldViewModel(for: type))
                if type == .country || type == .city {
                    fieldView.addTapHandler { [weak self] in
                        self?.onTapSelection?(type)
                    }
                } else {
                    fieldView.onTextUpdate = { [weak self] text in
                        self?.onTextUpdate?(type, text)
                    }
                }
                fieldsStackView.addArrangedSubview(fieldView)
            }

            self.stackView.addArrangedSubview(fieldsStackView)
        }

        let typeView = ContactAdditionFieldView()
        typeView.addTapHandler { [weak self] in
            self?.onTapSelection?(.type)
        }
        typeView.setup(with: viewModel.additionFieldViewModel(for: .type))
        self.stackView.addArrangedSubview(typeView)

        let commentView = ContactAdditionFieldView()
        commentView.setup(with: viewModel.additionFieldViewModel(for: .comment))
        commentView.onTextUpdate = { [weak self] text in
            self?.onTextUpdate?(.comment, text)
        }
        self.stackView.addArrangedSubview(commentView)

        if let isPrimary = viewModel.isPrimary, Config.isPersonalDataEditingAvailable {
			let model = viewModel.additionFieldViewModel(for: .primarySwitch)
			let primarySwitch = ContactAdditionSwitchFieldView()
			primarySwitch.onSwitchChanged = { [weak self] text in
				self?.onTextUpdate?(.primarySwitch, text)
			}
			primarySwitch.setup(with: model)

			primarySwitch.alpha = isPrimary ? 0.4 : 1.0
			primarySwitch.isUserInteractionEnabled = !isPrimary

			self.stackView.addArrangedSubview(primarySwitch)
		}

        switch viewModel.mode {
        case .addition:
            let title = { () -> String in
                switch viewModel.type {
                case .phone:
                    return Localization.localize("profile.add.phone")
                case .email:
                    return Localization.localize("profile.add.email")
                case .address:
                    return Localization.localize("profile.add.address")
                }
            }()
            let attributedTitle = title.attributed()
                .foregroundColor(self.appearance.addTextColor)
				.primeFont(ofSize: 16, lineHeight: 18)
                .string()

            self.saveButton.setAttributedTitle(attributedTitle, for: .normal)
        case .edit:
            let title = Localization.localize("profile.save").attributed()
                .foregroundColor(self.appearance.addTextColor)
				.primeFont(ofSize: 16, lineHeight: 18)
                .string()
            self.saveButton.setAttributedTitle(title, for: .normal)
        }
		self.buttonsStackView.isHidden = false
		let deleteButtonHidden = viewModel.type == .phone && viewModel.isPrimary == true
		self.deleteButton.isHidden = deleteButtonHidden
        if let isPrimary = viewModel.isPrimary, isPrimary, !Config.isPersonalDataEditingAvailable {
            self.configureImmutableView()
        }
    }

    func set(code: String) {
        let firstStackSubview = self.stackView.arrangedSubviews.first
        guard let phoneFieldView = firstStackSubview as? ContactAdditionPhoneFieldView else {
            fatalError("First view should be ContactAdditionPhoneFieldView")
        }
        phoneFieldView.set(code: code)
    }

    func set(contactType: ContactTypeViewModel) {
        let secondStackSubview = self.stackView.arrangedSubviews[1]
        guard let typeView = secondStackSubview as? ContactAdditionFieldView else {
            fatalError("First view should be ContactAdditionFieldView")
        }
        self.output?.contactType = contactType
        typeView.set(selectedType: contactType)
    }

    func set(city: City) {
        guard let fieldsStackView = self.stackView.subviews.first as? UIStackView else {
            assertionFailure("incorrect stackview subviews")
            return
        }

        guard let cityFieldView = fieldsStackView.subviews[1] as? ContactAdditionFieldView else {
            assertionFailure("incorrect stackview subview")
            return
        }

        cityFieldView.setup(with: .init(type: .city, value: city.name))
    }

    func set(country: Country) {
        guard let fieldsStackView = self.stackView.subviews.first as? UIStackView else {
            assertionFailure("incorrect stackview subviews")
            return
        }

        guard let countryFieldView = fieldsStackView.subviews[0] as? ContactAdditionFieldView else {
            assertionFailure("incorrect stackview subview")
            return
        }

        countryFieldView.setup(with: .init(type: .country, value: country.name))
    }

    private func listenToKeyboard() {
        self.keyboardHeightTracker = .init(view: self) { [weak self] height in
            self?.scrollView.contentInset.bottom = height
        }
        self.keyboardHeightTracker?.areAnimationsEnabled = true
    }

    private func configureImmutableView() {
        self.saveButton.isHidden = true
        self.deleteButton.isHidden = true
        self.stackView.isUserInteractionEnabled = false
        self.addSubview(self.chagneDataLabel)
        self.chagneDataLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.top.equalTo(self.stackView.snp.bottom).offset(20)
        }
    }
}

extension ContactAdditionView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.layer.cornerRadius = 8
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    func addSubviews() {
        self.addSubview(self.grabberView)
        self.addSubview(self.scrollView)

		self.scrollView.addSubview(self.stackView)
		self.scrollView.addSubview(self.buttonsStackView)
    }

    func makeConstraints() {
        self.grabberView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(10)
            make.centerX.equalToSuperview()
        }

        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.grabberView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        self.stackView.snp.makeConstraints { make in
            make.top.leading.trailing.width.equalToSuperview()
			make.width.equalToSuperview()
        }

        self.deleteButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.saveButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.buttonsStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.greaterThanOrEqualTo(self.stackView.snp.bottom).offset(10)
            make.bottom.equalTo(self.scrollView)
        }
    }
}
