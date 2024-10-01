import UIKit

extension ExpensesTableViewCell {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var separatorBackgroundColor = Palette.shared.gray3
        var titleTextColor = Palette.shared.gray0
        var subtitleTextColot = Palette.shared.gray1
		var imageBorderColor = Palette.shared.brandPrimary
    }
}

final class ExpensesTableViewCell: UITableViewCell, Reusable {
    private let appearance: Appearance

    private lazy var iconImageView = TaskInfoTypeView()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorBackgroundColor
        return view
    }()

    private lazy var titleLabel = UILabel()
    private lazy var priceLabel = UILabel()
    private lazy var timeLabel = UILabel()

    private lazy var hStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 15
        return stack
    }()
    private lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()

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

    func setup(with model: ExpensesViewModel) {
        self.titleLabel.attributedTextThemed = model.type.attributed()
            .foregroundColor(appearance.titleTextColor)
            .primeFont(ofSize: 15, lineHeight: 18)
            .lineBreakMode(.byTruncatingTail)
            .string()
        self.timeLabel.attributedTextThemed = model.category.attributed()
                .primeFont(ofSize: 12, lineHeight: 15)
                .foregroundColor(Palette.shared.gray1)
                .string()
        self.priceLabel.attributedTextThemed = "\(model.amount)".attributed()
            .primeFont(ofSize: 14, lineHeight: 17)
			.foregroundColor(Double(model.amount) ?> 0 ? Palette.shared.brandSecondary : Palette.shared.gray0)
            .string()
        self.iconImageView.set(image: model.image)
        self.iconImageView.layer.borderWidth = 1
		self.iconImageView.layer.borderColorThemed = self.appearance.imageBorderColor
    }

    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.selectionStyle = .none
    }

    func addSubviews() {
        [
            hStack,
            self.separatorView
        ].forEach(self.contentView.addSubview)

        let logoStack = with(UIStackView()) { stack in
            stack.axis = .vertical
            stack.addArrangedSubviews(
                .vSpacer(10),
                self.iconImageView,
                .vSpacer(growable: 6)
            )
        }
        self.vStack.addArrangedSubviews(
            .vSpacer(8),
            self.titleLabel,
            self.timeLabel,
            .vSpacer(8)
        )
        self.hStack.addArrangedSubviews(
            logoStack,
            vStack,
            self.priceLabel
        )
    }

    func makeConstraints() {
        self.contentView.make(.edges, .equalToSuperview)
        self.iconImageView.make(.size, .equal, [36, 36])
		self.hStack.make(.edges, .equalToSuperview, [0, 15, 0, -15])
        self.vStack.setContentHuggingPriority(.required, for: .horizontal)
        self.vStack.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.priceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		self.separatorView.make(.edges(except: .top), .equal, to: self.hStack)
    }
}
