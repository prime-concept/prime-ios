import UIKit

extension DetailRequestCreationView {
    struct Appearance: Codable {
        var assistantBackgroundColor = Palette.shared.gray5
        var assistantFont = Palette.shared.primeFont.with(size: 16)
        var assistantTextColor = Palette.shared.gray0
        var assistantBorderWidth: CGFloat = 0.5
        var assistantBorderColor = Palette.shared.gray3

        var buyBackgroundColor = Palette.shared.brandPrimary
        var buyFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
        var buyTextColor = Palette.shared.gray5

        var buttonCornerRadius: CGFloat = 8

        var backgroundColor = Palette.shared.gray5
    }
}

final class DetailRequestCreationView: UIView {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
		scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    private lazy var assistantButton: UIButton = {
        let button = UIButton(type: .system)

        // swiftlint:disable:next prime_font
        button.setTitle(
            Localization.localize("detailRequestCreation.viaAssistant"),
            for: .normal
        )
        button.titleLabel?.fontThemed = self.appearance.assistantFont
        button.setTitleColor(self.appearance.assistantTextColor, for: .normal)

        button.backgroundColorThemed = self.appearance.assistantBackgroundColor

        button.layer.borderWidth = self.appearance.assistantBorderWidth
        button.layer.borderColorThemed = self.appearance.assistantBorderColor

        button.layer.cornerRadius = self.appearance.buttonCornerRadius

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onAssistantButton?()
        }

        return button
    }()

    private lazy var buyButton: UIButton = {
        let button = UIButton(type: .system)

        // swiftlint:disable:next prime_font
        button.setTitle(Localization.localize("detailRequestCreation.selfBuy"), for: .normal)
        button.titleLabel?.fontThemed = self.appearance.buyFont
        button.setTitleColor(self.appearance.buyTextColor, for: .normal)

        button.backgroundColorThemed = self.appearance.buyBackgroundColor

        button.layer.cornerRadius = self.appearance.buttonCornerRadius

        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onBuyButton?()
        }

        return button
    }()

    private let appearance: Appearance

    var onBuyButton: (() -> Void)?
    var onAssistantButton: (() -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	func showLoading() {
		self.showLoadingIndicator()
	}

	func hideLoading() {
        HUD.find(on: self)?.remove(animated: true)
	}

    func set(views: [UIView]) {
        self.stackView.removeArrangedSubviews()
		self.stackView.addArrangedSubviews(views)

        if views.isEmpty == false {
            [
                self.buyButton, self.assistantButton
            ].forEach(self.buttonsStackView.addArrangedSubview)
        }
    }
}

extension DetailRequestCreationView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.addSubview(self.scrollView)
        [self.stackView, self.buttonsStackView].forEach(self.scrollView.addSubview)
    }

    func makeConstraints() {
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.stackView.snp.makeConstraints { make in
            make.top.leading.trailing.width.equalToSuperview()
        }

        self.buttonsStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-15)
            make.top.equalTo(self.stackView.snp.bottom).offset(19.5)
            make.height.equalTo(98)
        }
    }
}
