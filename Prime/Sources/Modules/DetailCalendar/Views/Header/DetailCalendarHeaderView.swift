import UIKit

extension DetailCalendarHeaderView {
    struct Appearance: Codable {
        var titleTextColor = Palette.shared.gray0
        var buttonTintColor = Palette.shared.gray0
    }
}

final class DetailCalendarHeaderView: UIView {
    private lazy var titleLabel = UILabel()

    private(set) lazy var leftButton: UIView = {
        let button = UIImageView(
            image: UIImage(named: "calendar-header-left-icon")?.withRenderingMode(.alwaysTemplate)
        )
        button.tintColorThemed = self.appearance.buttonTintColor
        return button.withExtendedTouchArea(insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }()

    private(set)  lazy var rightButton: UIView = {
        let button = UIImageView(
            image: UIImage(named: "calendar-header-right-icon")?.withRenderingMode(.alwaysTemplate)
        )
        button.tintColorThemed = self.appearance.buttonTintColor
        return button.withExtendedTouchArea(insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }()

    private let appearance: Appearance

    var changeMonth: ((_ isForward: Bool) -> Void)?

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(date: Date) {
		self.titleLabel.attributedTextThemed = date.string("LLLL yyyy")
			.capitalizingFirstLetter()
            .attributed()
            .primeFont(ofSize: 16, weight: .medium, lineHeight: 16)
            .foregroundColor(self.appearance.titleTextColor)
            .alignment(.center)
            .string()
    }
}

extension DetailCalendarHeaderView: Designable {
    func addSubviews() {
        [self.titleLabel, self.leftButton, self.rightButton].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(16)
        }

        self.leftButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 6, height: 12))
            make.trailing.equalTo(self.titleLabel.snp.leading).offset(-22)
            make.centerY.equalToSuperview()
        }

        self.rightButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 6, height: 12))
            make.leading.equalTo(self.titleLabel.snp.trailing).offset(22)
            make.centerY.equalToSuperview()
        }
    }

    func setupView() {
        self.leftButton.addTapHandler { [weak self] in
            self?.changeMonth?(false)
        }

        self.rightButton.addTapHandler { [weak self] in
            self?.changeMonth?(true)
        }
    }
}
