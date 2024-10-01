import UIKit

extension RequestListEmptyView {
    struct Appearance: Codable {
        var titleColor = Palette.shared.gray0
        var subtitleColor = Palette.shared.gray1
    }
}

final class RequestListEmptyView: UIView {
    private let appearance: Appearance

    private lazy var imageView = UIImageView(image: UIImage(named: "no_tasks_placeholder"))

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("home.empty.title").attributed()
            .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
            .alignment(.center)
            .foregroundColor(self.appearance.titleColor)
            .string()
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("home.empty.subtitle").attributed()
            .primeFont(ofSize: 13, lineHeight: 15)
            .alignment(.center)
            .foregroundColor(self.appearance.subtitleColor)
            .string()
        label.numberOfLines = 0
        return label
    }()

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

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let views = [self.titleLabel, self.subtitleLabel]
		let contentRect = views.reduce(self.imageView.frame) {
			return $0.union($1.frame)
		}

		return contentRect.contains(point)
	}
}

extension RequestListEmptyView: Designable {
    func addSubviews() {
        self.addSubview(self.imageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
    }

    func makeConstraints() {
        let isSmallScreen = (UIWindow.keyWindow?.frame.height ?? 0) <= 568

        self.imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.imageView.snp.bottom).offset(10)
            make.centerY.equalToSuperview().offset(isSmallScreen ? -30 : -15)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }

        self.subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }
    }
}
