import UIKit

extension AirportListLocationHeaderView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 15)
        var titleColor = Palette.shared.gray0

        var subtitleFont = Palette.shared.primeFont.with(size: 12)
        var subtitleColor = Palette.shared.gray1

        var separatorColor = Palette.shared.gray3

		var tintColor = Palette.shared.brandSecondary
    }
}

final class AirportListLocationHeaderView: UIView {
    private lazy var iconImageView: UIImageView = {
        let iconImage = UIImage(named: "content_geo")
        let imageView = UIImageView(image: iconImage)
        imageView.contentMode = .scaleAspectFill
		imageView.tintColorThemed = self.appearance.tintColor
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.titleFont
        label.textColorThemed = self.appearance.titleColor
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.subtitleFont
        label.textColorThemed = self.appearance.subtitleColor
        return label
    }()

    private lazy var expansionImageView = with(UIImageView()) {
        $0.contentMode = .scaleAspectFit
		$0.tintColorThemed = self.appearance.tintColor
    }

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()
    
    private lazy var disclosureIndicatorButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.setTitle("", for: .normal)
        
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.disclosureIndicatorButtonTap?()
        }
        return button
    }()
    
    private let appearance: Appearance
    var disclosureIndicatorButtonTap: (() -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: AirportListHeaderViewModel) {
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .font(self.appearance.titleFont)
            .foregroundColor(self.appearance.titleColor)
            .lineHeight(18)
            .string()
        self.subtitleLabel.attributedTextThemed = viewModel.subtitle.attributed()
            .font(self.appearance.subtitleFont)
            .foregroundColor(self.appearance.subtitleColor)
            .lineHeight(14.4)
            .string()

        let expandedImage = UIImage(named: "airport_arrow_up")
        let collapsedImage = UIImage(named: "airport_arrow_down")
        let expansionImage = viewModel.isExpanded ? expandedImage : collapsedImage
		self.expansionImageView.image = expansionImage?.withRenderingMode(.alwaysTemplate)
    }
}

extension AirportListLocationHeaderView: Designable {
    
    func addSubviews() {
        [
            self.iconImageView,
            self.titleLabel,
            self.subtitleLabel,
            self.separatorView,
            self.expansionImageView,
            self.disclosureIndicatorButton
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 14, height: 24))
            make.leading.equalToSuperview().offset(25)
            make.centerY.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(15)
            make.top.equalToSuperview().offset(9)
            make.trailing.lessThanOrEqualTo(self.expansionImageView.snp.leading).offset(-8)
        }

        self.subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(self.expansionImageView.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-8).priority(.high)
        }

        self.expansionImageView.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.centerY.equalTo(self.iconImageView)
            make.trailing.equalToSuperview()
        }
        self.disclosureIndicatorButton.snp.makeConstraints { make in
            make.width.equalTo(60)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
        }
    }
}

