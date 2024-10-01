import UIKit

extension HotelGuestsViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var clearBackgroundColor = Palette.shared.clear

        var saveButtonColor = Palette.shared.gray5
        var saveButtonBackgroundColor = Palette.shared.brandPrimary
        var deleteButtonColor = Palette.shared.gray0
    }
}

protocol HotelGuestsViewControllerProtocol: AnyObject {
    func setup(with fields: [HotelGuestsFormField])
    func addChildrenSectionHeader(with title: String)
    func add(child field: HotelGuestsFormField)
    func removeLastField()
    func update(_ field: HotelGuestsRowViewModel.Field, by amount: Int, isEnabled: Bool)
    func update(_ child: HotelGuestsChildRowViewModel, by amount: Int, isEnabled: Bool)
    func closeFormWithSuccess()
}

final class HotelGuestsViewController: UIViewController {
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
        label.attributedTextThemed = Localization.localize("form.reset")
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
        label.attributedTextThemed = Localization.localize("form.done")
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

    private lazy var grabberView = GrabberView(appearance: .init(height: 3))

    private let appearance: Appearance
    private let presenter: HotelGuestsPresenterProtocol

    init(
        presenter: HotelGuestsPresenterProtocol,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.presenter = presenter
        self.appearance = appearance

        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter.loadForm()
        self.saveButton.addTapHandler(self.presenter.saveForm)
        self.deleteButton.addTapHandler(self.presenter.resetForm)
        self.setupView()
    }

    deinit {
        DebugUtils.shared.log(sender: self, "is deinitialized")
    }

    // MARK: - Private

    private func setupView() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor
        [
            self.grabberView,
            self.stackView,
            self.buttonsStackView
        ].forEach(self.view.addSubview)

        self.grabberView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }

        self.stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.grabberView.snp.bottom).offset(13)
        }

        [
            self.deleteButton,
            self.saveButton
        ].forEach { view in
            view.snp.makeConstraints { make in
                make.height.equalTo(44)
            }
        }

        self.buttonsStackView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(44)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}

extension HotelGuestsViewController: HotelGuestsViewControllerProtocol {
    func setup(with fields: [HotelGuestsFormField]) {
        self.stackView.removeArrangedSubviews()
        fields.forEach {
            switch $0 {
            case .rowView(let model):
                let view = HotelGuestsRowView()
                view.onAddTap = { [unowned self] in
                    self.presenter.add(to: model.field)
                }
                view.onMinusTap = { [unowned self] in
                    self.presenter.subtract(from: model.field)
                }
                view.setup(viewModel: model)
                self.stackView.addArrangedSubview(view)
            case .headerView(let title):
                let headerView = HotelGuestsSectionHeaderView()
                headerView.setup(title: title)
                self.stackView.addArrangedSubview(headerView)
            case .childRowView(let child):
                let view = HotelGuestsRowView()
                view.onAddTap = { [unowned self] in
                    self.presenter.incrementAge(of: child)
                }
                view.onMinusTap = { [unowned self] in
                    self.presenter.decrementAge(of: child)
                }
                view.setup(with: child)
                self.stackView.addArrangedSubview(view)
            }
        }
    }

    func addChildrenSectionHeader(with title: String) {
        let headerView = HotelGuestsSectionHeaderView()
        headerView.setup(title: title)
        self.stackView.addArrangedSubview(headerView)
    }

    func add(child field: HotelGuestsFormField) {
        guard case let .childRowView(child) = field else {
            assertionFailure("Should add only child field")
            return
        }

        let view = HotelGuestsRowView()
        view.onAddTap = { [unowned self] in
            self.presenter.incrementAge(of: child)
        }
        view.onMinusTap = { [unowned self] in
            self.presenter.decrementAge(of: child)
        }
        view.setup(with: child)
        self.stackView.addArrangedSubview(view)
    }

    func removeLastField() {
        self.stackView.removeLastArrangedSubview()
    }

    func update(_ field: HotelGuestsRowViewModel.Field, by amount: Int, isEnabled: Bool) {
        _ = self.stackView.arrangedSubviews.first { view in
            if let rowView = view as? HotelGuestsRowView, rowView.field == field {
                rowView.editCount(by: amount, isEnabled: isEnabled)
                return true
            }
            return false
        }
    }

    func update(_ child: HotelGuestsChildRowViewModel, by amount: Int, isEnabled: Bool) {
        _ = self.stackView.arrangedSubviews.first { view in
            if let rowView = view as? HotelGuestsRowView, rowView.child == child {
                rowView.editCount(by: amount, isEnabled: isEnabled)
                return true
            }
            return false
        }
    }

    func closeFormWithSuccess() {
        self.dismiss(animated: true, completion: nil)
    }
}
