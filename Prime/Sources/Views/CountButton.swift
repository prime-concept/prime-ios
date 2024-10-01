import UIKit

extension CountButton {
    struct Appearance: Codable {
        var titleTextColor = Palette.shared.brandSecondary
        var titleFont = Palette.shared.primeFont.with(size: 12, weight: .medium)

        var countTextColor = Palette.shared.brandSecondary
        var countFont = Palette.shared.primeFont.with(size: 10)

        var borderColor = Palette.shared.brandSecondary
        var borderWidth: CGFloat = 0.5
        var cornerRadius: CGFloat = 0

        var selectionViewBackgroundColor = Palette.shared.brandPrimary

        init(with cornerRadius: CGFloat = 6) {
            self.cornerRadius = cornerRadius
        }
    }
}

final class CountButton: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColorThemed = self.appearance.titleTextColor
        label.fontThemed = self.appearance.titleFont
        label.textAlignment = .center
        return label
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColorThemed = self.appearance.countTextColor
        label.fontThemed = self.appearance.countFont
        return label
    }()

    private lazy var selectionView: OnePixelHeightView = {
        let view = OnePixelHeightView()
        view.isHidden = true
        view.backgroundColorThemed = self.appearance.selectionViewBackgroundColor
        return view
    }()

    private let appearance: Appearance

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

    func set(title: String, count: Int) {
        // swiftlint:disable:next prime_font
        self.titleLabel.text = title
        // swiftlint:disable:next prime_font
        self.countLabel.text = "\(count)"
    }

    func set(count: Int) {
        // swiftlint:disable:next prime_font
        self.countLabel.text = "\(count)"
    }

    func setup(with viewModel: CompletedTasksListHeaderItemViewModel) {
		self.titleLabel.attributedTextThemed = TaskType.taskType(viewModel.type.id)?.localizedName.attributed()
            .primeFont(ofSize: 12, weight: .medium, lineHeight: 16)
            .string()
        self.countLabel.attributedTextThemed = String(viewModel.count).attributed()
            .primeFont(ofSize: 10, weight: .medium, lineHeight: 12)
            .string()
        self.selectionView.isHidden = viewModel.isSelected == false
		self.alpha = viewModel.alpha
		self.isUserInteractionEnabled = viewModel.isEnabled
    }
}

extension CountButton: Designable {
    func setupView() {
        self.layer.borderColorThemed = self.appearance.borderColor
        self.layer.borderWidth = self.appearance.borderWidth
        self.layer.cornerRadius = self.appearance.cornerRadius

        self.titleLabel.setContentHuggingPriority(.init(rawValue: 250), for: .vertical)
        self.countLabel.setContentHuggingPriority(.init(rawValue: 251), for: .vertical)
    }

    func addSubviews() {
        [
            self.titleLabel,
            self.countLabel,
            self.selectionView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(5)
        }

        self.countLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }

        self.selectionView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-3)
            make.leading.trailing.equalTo(self.titleLabel)
        }
    }
}
