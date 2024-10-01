import UIKit

extension DetailRequestCreationCheckboxView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 15)
        var titleColor = Palette.shared.gray0

        var switchTintColor = Palette.shared.brandPrimary

        var separatorColor = Palette.shared.gray3
    }
}

final class DetailRequestCreationCheckboxView: UIView, TaskFieldValueInputProtocol {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.titleFont
        label.textColorThemed = self.appearance.titleColor
        return label
    }()

    private lazy var valueSwitch: UISwitch = {
        let view = UISwitch()
        view.onTintColorThemed = self.appearance.switchTintColor

        view.setEventHandler(for: .valueChanged) { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.onSwitchAction?(strongSelf.valueSwitch.isOn)
        }

        return view
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private let appearance: Appearance

    var onSwitchAction: ((Bool) -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 65)
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

    func setup(with viewModel: TaskCreationFieldViewModel) {
        // swiftlint:disable:next prime_font
        self.titleLabel.text = viewModel.title
        self.valueSwitch.isOn = viewModel.input.intValue == 1
    }
}

extension DetailRequestCreationCheckboxView: Designable {
    func setupView() {
    }

    func addSubviews() {
        [self.valueSwitch, self.titleLabel, self.separatorView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
        }

        self.separatorView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.valueSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalTo(self.separatorView.snp.top).offset(-11)
            make.leading.greaterThanOrEqualTo(self.titleLabel.snp.trailing).offset(5)
        }
    }
}
