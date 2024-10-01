import UIKit

extension TaskInfoTypeView {
    struct Appearance: Codable {
        var iconTintColor = Palette.shared.brandSecondary
        var iconSelectedTintColor = Palette.shared.gray5
        var backgroundColor = Palette.shared.gray5
        var selectedBackgroundColor = Palette.shared.brandPrimary
    }
}

final class TaskInfoTypeView: UIView {
    private(set) lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColorThemed = self.appearance.iconTintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let appearance: Appearance

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.frame.height / 2
    }

	func set(image: UIImage?, insets: UIEdgeInsets = .zero) {
        self.iconImageView.image = image?.withRenderingMode(.alwaysTemplate)
		self.iconImageView.snp.remakeConstraints { make in
			make.center.equalToSuperview().inset(insets)
		}
        self.setNeedsLayout()
    }

    func setSelected(_ isSelected: Bool) {
        let tintColor = isSelected ? self.appearance.iconSelectedTintColor : self.appearance.iconTintColor
        let backgroundColor = isSelected ? self.appearance.selectedBackgroundColor : self.appearance.backgroundColor
        self.backgroundColorThemed = backgroundColor
        self.layer.borderColorThemed = tintColor
        self.iconImageView.backgroundColorThemed = backgroundColor
        self.iconImageView.tintColorThemed = tintColor
    }
}

extension TaskInfoTypeView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.addSubview(self.iconImageView)
    }

    func makeConstraints() {
		self.iconImageView.make(.size, .equal, [20, 20])
        self.iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
