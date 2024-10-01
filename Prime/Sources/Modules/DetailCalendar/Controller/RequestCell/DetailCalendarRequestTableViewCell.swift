import UIKit

extension DetailCalendarRequestSectionHeaderView {
	struct Appearance: Codable {
		var textColor = Palette.shared.gray0
		var backgroundColor = Palette.shared.gray5
		var font = Palette.shared.primeFont.with(size: 15, weight: .medium)
		var insets: UIEdgeInsets = .tlbr(15, 15, 0, 15)

		var height: CGFloat {
			insets.top + ceil(font.rawValue.lineHeight) + insets.bottom
		}
	}
}

final class DetailCalendarRequestSectionHeaderView: UITableViewHeaderFooterView, Reusable {
	private(set) var appearance: Appearance = Theme.shared.appearance()

	private lazy var label = UILabel { (label: UILabel) in
		label.fontThemed = self.appearance.font
		label.textColorThemed = self.appearance.textColor
	}

	override init(reuseIdentifier: String?) {
		super.init(reuseIdentifier: reuseIdentifier)

		self.contentView.addSubview(self.label)
		self.contentView.backgroundColorThemed = self.appearance.backgroundColor

		let insets = self.appearance.insets
		self.label.make(
			.edges(except: .bottom),
			.equalToSuperview,
			[insets.top, insets.left, -insets.right],
			priorities: [.init(999)]
		)
	}

	func update(with title: String) {
		self.label.text = title
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension DetailCalendarNoDataCell {
	struct Appearance: Codable {
		var textColor = Palette.shared.gray1
		var backgroundColor = Palette.shared.gray5
		var font = Palette.shared.primeFont.with(size: 12, weight: .regular)
		var insets: UIEdgeInsets = .tlbr(15, 15, 6, 15)

		var height: CGFloat {
			insets.top + ceil(font.rawValue.lineHeight) + insets.bottom
		}
	}
}

final class DetailCalendarNoDataCell: UITableViewCell, Reusable {
	private(set) var appearance: Appearance = Theme.shared.appearance()

	private lazy var label = UILabel { (label: UILabel) in
		label.fontThemed = self.appearance.font
		label.textColorThemed = self.appearance.textColor
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.contentView.addSubview(self.label)
		self.contentView.backgroundColorThemed = self.appearance.backgroundColor
		
		let insets = self.appearance.insets
		self.label.make(
			.edges,
			.equalToSuperview,
			[insets.top, insets.left, -insets.bottom, -insets.right],
			priorities: [.init(999)]
		)
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		self.label.text = ""
	}

	func update(with title: String) {
		self.label.text = title
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

final class DetailCalendarRequestTableViewCell: UITableViewCell, Reusable {
    private lazy var requestView = DetailCalendarEventView()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.addSubviews()
		self.makeConstraints()
	}

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func setup(with viewModel: CalendarRequestItemViewModel) {
        self.requestView.setup(with: viewModel)
    }

    // MARK: - Private

    private func addSubviews() {
        self.contentView.addSubview(self.requestView)
    }

    private func makeConstraints() {
		self.requestView.make(.edges, .equalToSuperview, [5, 19, -5, -15])
    }
}
