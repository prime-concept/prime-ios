import UIKit

extension ContactAdditionFieldView {
    struct Appearance: Codable {
        var neutralSeparatorColor = Palette.shared.gray3
        var activeSeparatorColor = Palette.shared.gray0
        var textColor = Palette.shared.gray0
        var titleTextColor = Palette.shared.gray1
        var arrowTintColor = Palette.shared.gray1
    }
}

class ContactAdditionFieldView: UIView {
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.textColorThemed = self.appearance.textColor
        textField.setEventHandler(for: .editingChanged) { [weak self] in
            guard let self = self else {
                return
            }

            self.onTextUpdate?(self.output)
            self.updateLabel(isHidden: self.output.isEmpty)
        }
        textField.fontThemed = Palette.shared.primeFont.with(size: 15)
        return textField
    }()

    private lazy var arrowImageView: UIImageView = {
        let arrowImage = UIImage(named: "arrow_right")
        let imageView = UIImageView(image: arrowImage)
        imageView.isHidden = true
        imageView.tintColorThemed = self.appearance.arrowTintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.neutralSeparatorColor
        return view
    }()

    private lazy var titleLabel = UILabel()
    private lazy var containerView = UIView()
    private let appearance: Appearance

    var output: String {
        self.textField.text ?? ""
    }

    var onTextUpdate: ((String) -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 55)
    }

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

    func setup(with viewModel: ContactAdditionFieldViewModel) {
        self.textField.attributedPlaceholder = Localization.localize(viewModel.type.text).attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()

        switch viewModel.type {
        case .type, .country, .city:
            self.textField.isUserInteractionEnabled = false
            self.arrowImageView.isHidden = false
        default:
            break
        }
        self.titleLabel.attributedTextThemed = self.textField.placeholder?.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .string()
        self.textField.attributedTextThemed = viewModel.value.attributed()
            .foregroundColor(self.appearance.textColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()
        self.updateLabel(isHidden: viewModel.value.isEmpty)
    }

    func set(selectedType: ContactTypeViewModel) {
        self.textField.attributedTextThemed = selectedType.name.capitalizingFirstLetter().attributed()
            .foregroundColor(self.appearance.textColor)
            .primeFont(ofSize: 15, lineHeight: 20)
            .string()
        self.updateLabel(isHidden: selectedType.name.isEmpty)
    }

    // MARK: - Helpers

    private func updateLabel(isHidden: Bool) {
        guard self.titleLabel.isHidden || isHidden else {
            return
        }

        self.titleLabel.isHidden = isHidden
        self.textField.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(isHidden ? -15 : -11)
        }
    }
}

extension ContactAdditionFieldView: Designable {
    func setupView() {}

    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.titleLabel,
            self.textField,
            self.arrowImageView,
            self.separatorView
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8.5)
            make.leading.trailing.equalToSuperview()
        }

        self.textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.separatorView.snp.top).offset(-11)
        }

        self.arrowImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 5, height: 10))
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
}
