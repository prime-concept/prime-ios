import UIKit

extension ContactsListTableViewCell {
    struct Appearance: Codable {
        var titleColor = Palette.shared.gray1
        var subtitleColor = Palette.shared.gray0
        var separatorColor = Palette.shared.gray3
        var arrowTintColor = Palette.shared.gray1
    }
}

class ContactsListTableViewCell: UITableViewCell, Reusable {
    static let height: CGFloat = 65
    private lazy var arrowImageView: UIImageView = {
        let arrowImage = UIImage(named: "arrow_right")
        let imageView = UIImageView(image: arrowImage)
        imageView.tintColorThemed = self.appearance.arrowTintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var title = UILabel()
    private lazy var subTitle = UILabel()
	private lazy var badge = UnreadCountBadge()
	private lazy var badgeHolder = UIView()

    private let appearance: Appearance

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

    func setup(with viewModel: ContactsListTableViewCellViewModel) {
        self.title.attributedTextThemed = viewModel.title.attributed()
            .foregroundColor(self.appearance.titleColor)
            .primeFont(ofSize: 12, lineHeight: 16)
			.lineBreakMode(.byTruncatingTail)
            .string()
        self.subTitle.attributedTextThemed = viewModel.subTitle.attributed()
            .foregroundColor(self.appearance.subtitleColor)
            .primeFont(ofSize: 15, lineHeight: 20)
			.lineBreakMode(.byTruncatingTail)
            .string()
        self.separatorView.isHidden = viewModel.separatorIsHidden
		let badgeText = viewModel.badgeText ?? ""
		self.badge.update(
			with: UnreadCountBadge.ViewModel(
				text: badgeText,
				font: Palette.shared.primeFont.with(size: 12, weight: .medium),
				minTextHeight: 11,
				contentInsets: UIEdgeInsets(
					top: 7,
					left: 10,
					bottom: 6,
					right: 10
				)
			)
		)
		self.badgeHolder.isHidden = badgeText.isEmpty
    }

	private lazy var hStack = UIStackView(.horizontal)
}

extension ContactsListTableViewCell: Designable {
    func setupView() {
        self.backgroundColorThemed = Palette.shared.clear
    }

    func addSubviews() {
		let vStack = UIStackView(.vertical)
		vStack.addArrangedSubviews(
			self.title,
			.vSpacer(2),
			self.subTitle
		)

		let arrowImageStack = UIStackView(.vertical)
		arrowImageStack.addArrangedSubviews(
			.vSpacer(growable: 0),
			self.arrowImageView,
			.vSpacer(growable: 0)
		)
		arrowImageStack.arrangedSubviews[0]
			.make(.height, .equal, to: arrowImageStack.arrangedSubviews[2])


		self.badgeHolder.addSubview(self.badge)
		self.badge.snp.makeConstraints { make in
			make.centerY.equalToSuperview()
			make.trailing.equalToSuperview()
			make.leading.equalToSuperview().inset(10)
		}

		self.hStack.addArrangedSubviews(
			vStack,
			self.badgeHolder,
			.hSpacer(10),
			arrowImageStack
		)

		self.contentView.addSubview(self.hStack)
		self.contentView.addSubview(self.separatorView)
    }

    func makeConstraints() {
		self.hStack.make(.hEdges, .equalToSuperview, [15, -15])
		self.hStack.make(.centerY, .equalToSuperview)
		self.arrowImageView.make(.size, .equal, [15, 10])
		self.separatorView.make(.edges(except: .top), .equalToSuperview, [15, 0, -15])
    }
}
