import UIKit
import SwiftMaskText

extension CardEditViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var collectionBackgroundColor = Palette.shared.clear
        var collectionItemSize = CGSize(
            width: UIScreen.main.bounds.width,
            height: 55
         )
        var searchTextFieldCornerRadius: CGFloat = 10
        var searchHintFont = Palette.shared.primeFont.with(size: 12)
        var searchHintColor = Palette.shared.gray1
        var grabberViewBackgroundColor = Palette.shared.gray3
        var grabberCornerRadius: CGFloat = 2
        var applyBackgroundColor = Palette.shared.brandPrimary
        var applyTextColor = Palette.shared.gray5
        var clearTextColor = Palette.shared.gray0
        var clearBackgroundColor = Palette.shared.clear
        var clearBorderWidth: CGFloat = 0.5
        var clearBorderColor = Palette.shared.gray3
        var buttonCornerRadius: CGFloat = 8
        var saveButtonColor = Palette.shared.gray5
        var saveButtonBackgroundColor = Palette.shared.brandPrimary
        var deleteButtonColor = Palette.shared.danger
    }
}

protocol CardEditViewControllerProtocol: AnyObject {
    func update(with fields: [CardEditFormField])
    func presentTypesPicker(
        selected: DiscountType?,
        onSelect: @escaping (DiscountType) -> Void
    )
    func closeFormWithSuccess()
    func showActivity()
    func hideActivity()
    func show(error: String)
    func update(with cardModel: CardEditPickerModel)
}

final class CardEditViewController: UIViewController {
	private lazy var grabberView: UIView = {
		let view = UIView()
		view.backgroundColorThemed = self.appearance.grabberViewBackgroundColor
		view.clipsToBounds = true
		view.layer.cornerRadius = 2
		return view
	}()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.backgroundColorThemed = self.appearance.collectionBackgroundColor
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
    private lazy var cardEditPickerFieldView = CardEditPickerFieldView()

    private let appearance: Appearance
    private let presenter: CardEditPresenterProtocol
    private let canDelete: Bool
    private var keyboardHeightTracker: PrimeKeyboardHeightTracker?

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
		scrollView.addSubview(self.stackView)
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    init(presenter: CardEditPresenterProtocol, canDelete: Bool, appearance: Appearance = Theme.shared.appearance()) {
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
        [self.scrollView, self.buttonsStackView].forEach(self.view.addSubview)

		self.view.addSubview(self.grabberView)
		self.grabberView.snp.makeConstraints { make in
			make.top.equalToSuperview().offset(10)
			make.centerX.equalToSuperview()
			make.width.equalTo(35)
			make.height.equalTo(3)
		}

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
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-15)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }

    func update(with cardModel: CardEditPickerModel) {
        cardEditPickerFieldView.setup(with: cardModel)
    }
}

extension CardEditViewController: CardEditViewControllerProtocol {
    func update(with fields: [CardEditFormField]) {
        fields.forEach {
            switch $0 {
            case .textField(let model):
                let textField = CardEditFieldView()
                textField.setup(with: model)
                self.stackView.addArrangedSubview(textField)
            case .picker(let model):
                let textField = CardEditPickerFieldView()
                self.cardEditPickerFieldView = textField
                textField.setup(with: model)
                self.stackView.addArrangedSubview(textField)
            }
        }
    }

    func presentTypesPicker(selected: DiscountType?, onSelect: @escaping (DiscountType) -> Void) {
        let assembly = CardTypeSelectionAssembly(
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
        alert.addAction(.init(title: "common.ok".localized.uppercased(), style: .default, handler: nil))

        self.present(alert, animated: true)
    }
}
