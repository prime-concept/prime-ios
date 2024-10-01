import UIKit

extension PersonEditViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var clearBackgroundColor = Palette.shared.clear
        var grabberViewBackgroundColor = Palette.shared.gray3
        var saveButtonColor = Palette.shared.gray5
        var saveButtonBackgroundColor = Palette.shared.brandPrimary
        var deleteButtonColor = Palette.shared.danger
    }
}

protocol PersonEditViewControllerProtocol: AnyObject {
    func update(with fields: [FamilyEditFormField])
    func presentPersonsTypePicker(
        selected: ContactType?,
        onSelect: @escaping (ContactType) -> Void
    )
    func closeFormWithSuccess()
    func showActivity()
    func hideActivity()
    func show(error: String)
    func update(with contactModel: FamilyEditPickerModel)
}

final class PersonEditViewController: UIViewController {
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.backgroundColorThemed = self.appearance.clearBackgroundColor
        return stackView
    }()

    private lazy var buttonsStackView: UIStackView = {
        let buttonStack = UIStackView(arrangedSubviews: [self.deleteButton, self.saveButton])
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 5
        return buttonStack
    }()

    private lazy var deleteButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("cards.form.delete")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.deleteButtonColor)
            .string()

        label.clipsToBounds = true
        label.layer.cornerRadius = 8

        label.layer.borderColorThemed = Palette.shared.gray3
        label.layer.borderWidth = 1 / UIScreen.main.scale

        return label
    }()

    private lazy var saveButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("cards.form.save")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.saveButtonColor)
            .string()

        label.backgroundColorThemed = self.appearance.saveButtonBackgroundColor

        label.clipsToBounds = true
        label.layer.cornerRadius = 8

        return label
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.addSubview(self.stackView)
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let appearance: Appearance
    private let presenter: PersonEditPresenterProtocol
    private let canDelete: Bool
    private var keyboardHeightTracker: PrimeKeyboardHeightTracker?
    private lazy var familyEditPickerFieldView = FamilyEditPickerFieldView()
    
    init(
        presenter: PersonEditPresenterProtocol,
        canDelete: Bool,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.presenter = presenter
        self.appearance = appearance
        self.canDelete = canDelete

        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.keyboardHeightTracker = .init(view: self.view) { [weak self] height in
            let newConstraint = height + 15
            self?.buttonsStackView.snp.remakeConstraints { make in
				make.bottom.equalToSuperview().inset(newConstraint)
                make.leading.trailing.equalToSuperview().inset(15)
            }
        }
        self.presenter.loadForm()
        self.saveButton.addTapHandler(self.presenter.saveForm)
        self.deleteButton.addTapHandler(self.presenter.deleteForm)
        self.setupView()
    }

    // MARK: - Private

    private func setupView() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor
        [
            self.scrollView,
            self.buttonsStackView
        ].forEach(self.view.addSubview)

        self.deleteButton.isHidden = !canDelete
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.buttonsStackView.snp.top).offset(-10)
        }
        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        self.deleteButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.saveButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.buttonsStackView.snp.makeConstraints { make in
			make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(15)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}

extension PersonEditViewController: PersonEditViewControllerProtocol {
    func update(with contactModel: FamilyEditPickerModel) {
        familyEditPickerFieldView.setup(with: contactModel)
    }
    
    func update(with fields: [FamilyEditFormField]) {
        fields.forEach {
            switch $0 {
            case .textField(let model):
                let textField = FamilyEditFieldView()
                textField.setup(with: model)
                self.stackView.addArrangedSubview(textField)
            case .picker(let model):
                let textField = FamilyEditPickerFieldView()
                self.familyEditPickerFieldView = textField
                textField.setup(with: model)
                self.stackView.addArrangedSubview(textField)
            case .datePicker(let model):
                let textField = FamilyEditDateFieldView()
                textField.setup(with: model)
                self.stackView.addArrangedSubview(textField)
            }
        }
    }
    
    func presentPersonsTypePicker(selected: ContactType?, onSelect: @escaping (ContactType) -> Void) {
        self.view.endEditing(true)
        let assembly = FamilyTypeSelectionAssembly(
            selectedType: selected,
            onSelect: { x in
                onSelect(x)
            }
        )
        let controller = assembly.make()
        self.present(controller, animated: true, completion: nil)
    }
    
    func closeFormWithSuccess() {
        self.dismiss(animated: true, completion: nil)
    }

    func showActivity() {
		self.view.showLoadingIndicator()
    }

    func hideActivity() {
        HUD.find(on: self.view)?.remove()
    }

    func show(error: String) {
        HUD.find(on: self.view)?.remove()

        let alert = UIAlertController(title: nil, message: error, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))

        self.present(alert, animated: true)
    }
}
