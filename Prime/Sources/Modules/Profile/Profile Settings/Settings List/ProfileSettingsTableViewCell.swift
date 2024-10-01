import UIKit

extension ProfileSettingsTableViewCell {
    struct Appearance: Codable {
        var expandTintColor = Palette.shared.brandSecondary
    }
}

final class ProfileSettingsTableViewCell: UITableViewCell, Reusable {
    private(set) lazy var separatorView = with(OnePixelHeightView()) {
        $0.backgroundColorThemed = Palette.shared.gray3
    }

	private lazy var stackView = with(UIStackView(.horizontal)) { stackView in
		stackView.spacing = 10
		stackView.alignment = .center
	}

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

	private lazy var titleLabel = with(UILabel()) { label in
		label.numberOfLines = 2
	}
    
    private var appearance: Appearance

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.appearance = Theme.shared.appearance()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ProfileSettingViewModel) {
		self.iconImageView.isHidden = viewModel.icon == nil
		if let imageName = viewModel.icon {
            self.iconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
            self.iconImageView.tintColorThemed = self.appearance.expandTintColor
		}
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .primeFont(ofSize: 15, lineHeight: 18)
			.foregroundColor(viewModel.titleColor)
			.lineBreakMode(.byWordWrapping)
            .string()
		self.makeStackConstraints(with: viewModel.contentInsets)
    }
}

extension ProfileSettingsTableViewCell: Designable {
    func setupView() {
        self.contentView.backgroundColorThemed = Palette.shared.gray5
        self.separatorView.backgroundColorThemed = Palette.shared.gray3
    }

    func addSubviews() {
		self.contentView.addSubview(self.stackView)
		self.stackView.addArrangedSubview(self.iconImageView)
		self.stackView.addArrangedSubview(self.titleLabel)
		self.contentView.addSubview(self.separatorView)
	}

    func makeConstraints() {
		self.makeStackConstraints()

        self.iconImageView.snp.makeConstraints { make in
            make.height.width.equalTo(44)
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }

	private func makeStackConstraints(with insets: UIEdgeInsets = .zero) {
		self.stackView.snp.remakeConstraints { make in
			make.edges.equalToSuperview().inset(insets)
			make.height.equalTo(56 - insets.top - insets.bottom)
		}
	}
}
