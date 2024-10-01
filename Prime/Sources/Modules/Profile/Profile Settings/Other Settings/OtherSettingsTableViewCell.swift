import UIKit

final class OtherSettingsTableViewCell: UITableViewCell, Reusable {
    private lazy var separatorView = with(OnePixelHeightView()) {
        $0.backgroundColorThemed = Palette.shared.gray3
    }

    private lazy var titleLabel = UILabel()
    private lazy var valueLabel = UILabel()
	private lazy var toggle = with(UISwitch()) { (toggle: UISwitch) in
		toggle.onTintColorThemed = Palette.shared.brandPrimary
		toggle.thumbTintColorThemed = Palette.shared.gray5
	}

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: OtherSettingViewModel) {
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .primeFont(ofSize: 15, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0)
            .string()

        self.valueLabel.attributedTextThemed = viewModel.value.attributed()
            .primeFont(ofSize: 14, lineHeight: 16.8)
            .foregroundColor(Palette.shared.gray0)
            .string()

		self.configureToggle(with: viewModel)
		self.configureButton(with: viewModel)

		self.separatorView.isHidden = viewModel.isLast
    }

	private func configureToggle(with viewModel: OtherSettingViewModel) {
		let isToggle = viewModel.kind == .toggle

		self.toggle.isHidden = !isToggle
		self.valueLabel.isHidden = isToggle

		guard isToggle else {
			return
		}

		self.toggle.isOn = UserDefaults[bool: viewModel.value]
		self.toggle.setEventHandler(for: .valueChanged) { [weak toggle] in
			guard let toggle = toggle else {
				return
			}
			UserDefaults[bool: viewModel.value] = toggle.isOn
		}
	}

	private func configureButton(with viewModel: OtherSettingViewModel) {
		guard viewModel.kind == .button else {
			self.removeTapHandler()
			return
		}

		self.addTapHandler {
			viewModel.action?()
		}
	}
}

extension OtherSettingsTableViewCell: Designable {
    func setupView() {
        self.contentView.backgroundColorThemed = Palette.shared.gray5
        self.separatorView.backgroundColorThemed = Palette.shared.gray3
    }

    func addSubviews() {
		self.contentView.addSubview(self.separatorView)
    }

    func makeConstraints() {
		let hStack = UIStackView.horizontal(
			self.titleLabel, self.valueLabel, self.toggle
		)

		hStack.spacing = 15
		hStack.alignment = .center

		self.contentView.addSubview(hStack)
		hStack.make(.height, .equal, 55)
		hStack.make(.edges, .equalToSuperview, [0, 15, 0, -15])

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}
