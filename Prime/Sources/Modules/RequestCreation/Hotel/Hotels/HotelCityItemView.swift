import SnapKit
import UIKit

extension HotelCityItemView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 15)
        var titleColor = Palette.shared.gray0

        var subtitleFont = Palette.shared.primeFont.with(size: 12)
        var subtitleColor = Palette.shared.gray1

        var separatorColor = Palette.shared.gray3

		var tintColor = Palette.shared.brandSecondary
    }
}

final class HotelCityItemView: UIView {
    private lazy var iconImageView: UIImageView = {
        let iconImage = UIImage(named: "content_geo")
        let imageView = UIImageView(image: iconImage)
        imageView.contentMode = .scaleAspectFill
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

    func setup(with viewModel: HotelCityViewModel) {
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .font(self.appearance.titleFont)
            .foregroundColor(self.appearance.titleColor)
            .lineBreakMode(.byTruncatingTail)
            .lineHeight(18)
            .string()

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
    }
}

extension HotelCityItemView: Designable {
    func addSubviews() {
        [
            self.iconImageView,
            self.titleLabel,
            self.subtitleLabel,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 14, height: 24))
            make.leading.equalToSuperview().offset(25)
            make.centerY.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            self.titleCenterYConstraint = make.centerY.equalToSuperview().constraint
            self.titleCenterYConstraint?.deactivate()
            self.titleTopConstraint = make.top.equalToSuperview().offset(10).constraint

            make.leading.equalTo(self.iconImageView.snp.trailing).offset(15)
            make.trailing.equalTo(self.separatorView)
        }

        self.subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}


