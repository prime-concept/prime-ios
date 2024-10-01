import UIKit

final class PersonsItemCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var nameLabel = UILabel()
    private lazy var contactTypeLabel = UILabel()
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "personal_data_icon")
        imageView.backgroundColorThemed = Palette.shared.gray5
		imageView.tintColorThemed = Palette.shared.brandSecondary
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        return imageView
    }()

    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                super.isSelected = true
                self.select()
            } else {
                super.isSelected = false
                self.deselect()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: PersonInfoViewModel) {
		self.nameLabel.attributedTextThemed = Self.makeNameText(viewModel.shortName)
		self.contactTypeLabel.attributedTextThemed = Self.makeNumberText(viewModel.contactType)
		self.makeLabelsMultiline()
    }

    func select() {
        self.resetShadow()
        self.backgroundColorThemed = Palette.shared.brandPrimary

		self.contactTypeLabel.textColorThemed = Palette.shared.gray5
        self.nameLabel.textColorThemed = Palette.shared.gray5

		self.makeLabelsMultiline()
    }

    func deselect() {
        self.backgroundColorThemed = Palette.shared.gray5

        self.contactTypeLabel.textColorThemed = Palette.shared.gray1
        self.nameLabel.textColorThemed = Palette.shared.gray0

		self.makeLabelsMultiline()

        self.dropShadow(
            offset: .init(width: 0, height: 3),
            radius: 10,
			color: Palette.shared.black.withAlphaComponent(0.1),
            opacity: 0.8
        )
    }

    private static func makeNameText(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, weight: .medium, lineHeight: 14.4)
            .foregroundColor(Palette.shared.gray0)
            .lineBreakMode(.byWordWrapping)
            .alignment(.center)
            .string()
    }

    private static func makeNumberText(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 10, weight: .regular, lineHeight: 12)
            .foregroundColor(Palette.shared.gray1)
            .alignment(.center)
			.lineBreakMode(.byWordWrapping)
            .string()
    }

	private func makeLabelsMultiline() {
		[self.nameLabel, self.contactTypeLabel].forEach {
			$0.lineBreakMode = .byWordWrapping
			$0.numberOfLines = 2
		}
	}
}

extension PersonsItemCollectionViewCell: Designable {
    func setupView() {
        self.backgroundColorThemed = Palette.shared.gray5
        self.imageView.layer.borderWidth = 1
        self.imageView.layer.borderColorThemed = Palette.shared.gray5
        self.layer.cornerRadius = 10.0
        self.layer.masksToBounds = true
    }

    func addSubviews() {
        [
            self.nameLabel,
            self.contactTypeLabel,
            self.imageView
        ].forEach(self.contentView.addSubview)

        self.dropShadow(
            offset: .init(width: 0, height: 3),
            radius: 10,
            color:Palette.shared.black.withAlphaComponent(0.1),
            opacity: 0.8
        )
    }
    
    func makeConstraints() {
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().priority(UILayoutPriority.defaultHigh)
			make.height.equalTo(self.contentView.snp.width)
			make.width.equalTo(100)
        }

		self.imageView.snp.makeConstraints { make in
			make.top.greaterThanOrEqualToSuperview().inset(10)
			make.top.lessThanOrEqualToSuperview().inset(15)

			make.size.greaterThanOrEqualTo(CGSize(width: 30, height: 30))
            make.size.lessThanOrEqualTo(CGSize(width: 40, height: 40))
			make.centerX.equalToSuperview()
        }

		self.nameLabel.snp.makeConstraints { make in
			make.leading.trailing.equalToSuperview().inset(4)
			make.top.greaterThanOrEqualTo(self.imageView.snp.bottom).offset(4)
            make.top.lessThanOrEqualTo(self.imageView.snp.bottom).offset(11)
        }

        self.contactTypeLabel.snp.makeConstraints { make in
            make.top.equalTo(self.nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(4)

			make.bottom.lessThanOrEqualToSuperview().inset(4)
			make.bottom.greaterThanOrEqualToSuperview().inset(7)
        }
    }
}
