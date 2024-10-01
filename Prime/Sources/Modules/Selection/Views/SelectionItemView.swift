import UIKit

extension SelectionItemView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 15)
        var titleColor = Palette.shared.gray0
		var descriptionFont = Palette.shared.primeFont.with(size: 12)
		var descriptionColor = Palette.shared.gray1
		var iconTintColor = Palette.shared.gray0
        var separatorColor = Palette.shared.custom_lightGray2
    }
}

final class SelectionItemView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.titleFont
        label.textColorThemed = self.appearance.titleColor
        return label
    }()

	private lazy var descriptionLabel: UILabel = {
		let label = UILabel()
		label.fontThemed = self.appearance.descriptionFont
		label.textColorThemed = self.appearance.descriptionColor
		return label
	}()

    private lazy var hStack: UIStackView = {
        let vStack = UIStackView()
        vStack.axis = .horizontal
        vStack.spacing = 5
        vStack.alignment = .center
        return vStack
    }()

	private lazy var vStack: UIStackView = {
		let vStack = UIStackView()
		vStack.axis = .vertical
		vStack.spacing = 5
		vStack.alignment = .leading
		return vStack
	}()

    private lazy var selectedIconImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(named: "selected-mark-icon")?.withRenderingMode(.alwaysTemplate)
        )
        imageView.tintColorThemed = self.appearance.iconTintColor
        imageView.isHidden = true
        return imageView
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private let appearance: Appearance

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

	func setup(
		value: String,
		description: String? = nil,
		isSelected: Bool
	) {
        // swiftlint:disable prime_font
        self.titleLabel.text = value
		self.descriptionLabel.text = description
		self.descriptionLabel.isHidden = (description ?? "").isEmpty
        self.selectedIconImageView.isHidden = !isSelected
		// swiftlint:enable prime_font
    }
}

extension SelectionItemView: Designable {
    func addSubviews() {
		self.vStack.addArrangedSubview(self.titleLabel)
		self.vStack.addArrangedSubview(self.descriptionLabel)
        self.hStack.addArrangedSubview(self.vStack)
        self.hStack.addArrangedSubview(self.selectedIconImageView)
		[self.hStack, self.separatorView].forEach(self.addSubview)
    }

    func makeConstraints() {
		self.hStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
			make.top.bottom.equalToSuperview().inset(10)
		}

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }

        self.selectedIconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 12, height: 8))
        }
    }
}
