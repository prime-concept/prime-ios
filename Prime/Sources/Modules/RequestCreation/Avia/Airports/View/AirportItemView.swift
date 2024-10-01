import SnapKit
import UIKit

extension AirportItemView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 15)
        var titleColor = Palette.shared.gray0

        var subtitleFont = Palette.shared.primeFont.with(size: 12)
        var subtitleColor = Palette.shared.gray1

        var codeFont = Palette.shared.primeFont.with(size: 17)
        var codeColor = Palette.shared.brandPrimary

        var distanceFont = Palette.shared.primeFont.with(size: 11)
        var distanceColor = Palette.shared.gray1

        var separatorColor = Palette.shared.gray3
		var tintColor = Palette.shared.brandSecondary
    }
}

final class AirportItemView: UIView {
    private lazy var iconImageView: UIImageView = {
        let iconImage = UIImage(named: "avia_icon")
        let imageView = UIImageView(image: iconImage)
        imageView.contentMode = .scaleAspectFit
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

    private lazy var codeLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.codeFont
        label.textColorThemed = self.appearance.codeColor
        return label
    }()

    private lazy var distanceLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.distanceFont
        label.textColorThemed = self.appearance.distanceColor
        return label
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private var titleCenterYConstraint: Constraint?
    private var subtitleTrailingConstraint: Constraint?
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

    func setup(with viewModel: AirportViewModel) {
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .font(self.appearance.titleFont)
            .foregroundColor(self.appearance.titleColor)
            .lineHeight(18)
            .string()
        self.codeLabel.attributedTextThemed = viewModel.code.attributed()
            .font(self.appearance.codeFont)
            .foregroundColor(self.appearance.codeColor)
            .lineHeight(17)
            .string()

        self.set(subtitle: viewModel.subtitle^)
        self.set(distance: viewModel.distance^)
    }

    func reset() {
        self.titleLabel.attributedTextThemed = nil
        self.subtitleLabel.attributedTextThemed = nil
        self.codeLabel.attributedTextThemed = nil
        self.distanceLabel.attributedTextThemed = nil
    }

    private func set(subtitle: String) {
        if subtitle.isEmpty {
           return
        }

        self.subtitleLabel.attributedTextThemed = subtitle.attributed()
            .font(self.appearance.subtitleFont)
            .foregroundColor(self.appearance.subtitleColor)
            .lineHeight(14.4)
            .string()
        self.titleCenterYConstraint?.deactivate()
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
        }
        self.subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            self.subtitleTrailingConstraint = make.trailing.equalToSuperview().inset(15).constraint
            make.bottom.equalToSuperview().offset(-8).priority(.high)
        }
    }

    private func set(distance: String) {
        if !distance.isEmpty {
            self.distanceLabel.attributedTextThemed = distance.attributed()
                .font(self.appearance.distanceFont)
                .foregroundColor(self.appearance.distanceColor)
                .lineHeight(13.2)
                .string()
            self.distanceLabel.snp.makeConstraints { make in
                make.centerY.equalTo(self.subtitleLabel)
                make.trailing.equalTo(self.codeLabel)
            }
            self.subtitleTrailingConstraint?.deactivate()
            self.subtitleLabel.snp.makeConstraints { make in
				make.trailing.lessThanOrEqualTo(self.distanceLabel.snp.leading).offset(-8).priority(.init(999))
            }
            self.distanceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }
}

extension AirportItemView: Designable {
    func addSubviews() {
        [
            self.iconImageView,
            self.titleLabel,
            self.subtitleLabel,
            self.codeLabel,
            self.distanceLabel,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.leading.equalToSuperview().offset(23)
            make.centerY.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            self.titleCenterYConstraint = make.centerY.equalToSuperview().constraint
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(15)
            make.trailing.lessThanOrEqualTo(self.codeLabel.snp.leading).offset(-8)
        }

        self.codeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel)
            make.trailing.equalToSuperview().inset(15)
        }
        self.codeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}
