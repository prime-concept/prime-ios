import SnapKit
import UIKit

extension HotelItemView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 15)
        var titleColor = Palette.shared.gray0

        var subtitleFont = Palette.shared.primeFont.with(size: 12)
        var subtitleColor = Palette.shared.gray1

        var distanceFont = Palette.shared.primeFont.with(size: 11)
        var distanceColor = Palette.shared.gray1

        var separatorColor = Palette.shared.gray3
		var tintColor = Palette.shared.brandSecondary
    }
}

final class HotelItemView: UIView {
    private lazy var iconImageView: UIImageView = {
        let iconImage = UIImage(named: "hotel_request_icon")
        let imageView = UIImageView(image: iconImage)
        imageView.contentMode = .scaleAspectFit
		imageView.tintColorThemed = self.appearance.tintColor
        return imageView
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var titleLabel = UILabel()
    private lazy var subtitleLabel = UILabel()
    private lazy var starsView = UIStackView(.horizontal)
    private lazy var distanceLabel = UILabel()

    private var titleTopConstraint: Constraint?
    private var titleCenterYConstraint: Constraint?

    private let appearance: Appearance

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

    func setup(with viewModel: HotelViewModel) {
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .font(self.appearance.titleFont)
            .foregroundColor(self.appearance.titleColor)
            .lineBreakMode(.byTruncatingTail)
            .lineHeight(18)
            .string()
        self.distanceLabel.attributedTextThemed = viewModel.distance?.attributed()
            .font(self.appearance.distanceFont)
            .foregroundColor(self.appearance.distanceColor)
            .lineHeight(13.2)
            .string()
        self.draw(stars: viewModel.stars ?? 0)

        guard !viewModel.subtitle.isEmpty else {
            self.titleTopConstraint?.deactivate()
            self.titleCenterYConstraint?.activate()
            return
        }
        self.subtitleLabel.attributedTextThemed = viewModel.subtitle.attributed()
            .font(self.appearance.subtitleFont)
            .foregroundColor(self.appearance.subtitleColor)
            .lineBreakMode(.byTruncatingTail)
            .lineHeight(15)
            .string()
        self.titleTopConstraint?.activate()
        self.titleCenterYConstraint?.deactivate()
    }

    func reset() {
        self.titleLabel.attributedTextThemed = nil
        self.subtitleLabel.attributedTextThemed = nil
        self.starsView.removeArrangedSubviews()
    }

    private func draw(stars: Int) {
        guard stars >= 1 else {
            return
        }

        for star in 1...stars {
            let starImageView = UIImageView(image: UIImage(named: "hotel_star"))
			starImageView.tintColorThemed = self.appearance.tintColor
            starImageView.frame.size = CGSize(width: 12, height: 12)
            self.starsView.addArrangedSubview(starImageView)
            if star != stars {
                self.starsView.addArrangedSpacer(3)
            }
        }
    }
}

extension HotelItemView: Designable {
    func addSubviews() {
        [
            self.iconImageView,
            self.titleLabel,
            self.subtitleLabel,
            self.starsView,
            self.distanceLabel,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            self.titleCenterYConstraint = make.centerY.equalToSuperview().constraint
            self.titleCenterYConstraint?.deactivate()
            self.titleTopConstraint = make.top.equalToSuperview().offset(10).constraint

            make.leading.equalTo(self.iconImageView.snp.trailing).offset(15)
            make.trailing.equalToSuperview().offset(-94)
        }

        self.subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.trailing.lessThanOrEqualTo(self.distanceLabel.snp.leading).offset(-10)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
        }

        self.starsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.trailing.equalTo(self.separatorView)
        }
        self.starsView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        self.distanceLabel.snp.makeConstraints { make in
            make.top.equalTo(self.starsView.snp.bottom).offset(9)
            make.trailing.equalTo(self.separatorView)
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
