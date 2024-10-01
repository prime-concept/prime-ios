import UIKit

private let titleFont = Palette.shared.primeFont.with(size: 14)
private let subtitleFont = Palette.shared.primeFont.with(size: 12)

extension CalendarRequestItemView {
    struct Appearance: Codable {
        var titleTextColor = Palette.shared.gray0

        var subtitleTextColor = Palette.shared.gray1
        var bottomTextColor = Palette.shared.brandSecondary
        var logoBorderWidth: CGFloat = 0.5
        var logoBorderColor = Palette.shared.brandSecondary
    }
}

final class CalendarRequestItemView: UIView {
    private lazy var logoView: TaskInfoTypeView = {
        let view = TaskInfoTypeView()
        view.backgroundColorThemed = Palette.shared.clear
        return view
    }()

    private lazy var titleLabel = UILabel()

    private lazy var subtitleLabel = UILabel()

    private lazy var bottomLabel: UILabel = {
        let label = UILabel()
		label.attributedTextThemed = "task.hasReservation".localized.attributed()
            .foregroundColor(self.appearance.bottomTextColor)
			.font(Palette.shared.primeFont.with(size: 12))
			.lineHeight(14)
            .string()
        return label
    }()

    private lazy var stackLabelsView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleLabel])
        view.axis = .vertical
        return view
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
        self.layer.cornerRadius = self.frame.width / 2
    }

	// MARK: - Helpers
	private lazy var taskIdLabel = UILabel { (label: UILabel) in
		label.font = .systemFont(ofSize: 16)
		label.textColor = .red
		label.alpha = 0.3
		label.textAlignment = .center
		label.adjustsFontSizeToFitWidth = true

		self.addSubview(label)
		label.make([.bottom, .leading], .equalToSuperview, [-5, 5])
	}

    func setup(with viewModel: CalendarRequestItemViewModel) {
		if let task = viewModel.task {
			let taskId = task.taskID
			self.taskIdLabel.text = "\(taskId) (\(task.events.count))[\(task.attachedFiles.count)]"
			self.taskIdLabel.isHidden = !UserDefaults[bool: "showsTaskIdsOnTasks"]
		} else {
			self.taskIdLabel.isHidden = true
		}

        self.titleLabel.attributedTextThemed = viewModel.attributedTitle(appearance: self.appearance)
        self.subtitleLabel.attributedTextThemed = viewModel.attributedSubtitle(appearance: self.appearance)
        self.bottomLabel.isHidden = true
        self.subtitleLabel.numberOfLines = 2

        self.logoView.set(image: viewModel.logo)
    }
}

extension CalendarRequestItemView: Designable {
    func setupView() {
        self.backgroundColorThemed = Palette.shared.clear

        self.logoView.layer.borderWidth = self.appearance.logoBorderWidth
        self.logoView.layer.borderColorThemed = self.appearance.logoBorderColor
    }

    func addSubviews() {
        [
            self.logoView,
            self.stackLabelsView,
            self.bottomLabel
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.logoView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 36, height: 36))
            make.leading.equalToSuperview()
			make.top.equalTo(self.titleLabel).inset(titleFont.rawValue.topGapHeight / 2)
        }

        self.stackLabelsView.snp.makeConstraints { make in
			make.top.equalToSuperview()
            make.leading.equalTo(self.logoView.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualToSuperview()
        }

        self.bottomLabel.snp.makeConstraints { make in
            make.top.equalTo(self.logoView.snp.bottom)
            make.centerX.equalTo(self.logoView.snp.centerX)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
}

private extension CalendarRequestItemViewModel {
	private static let attributedStringsCache = NSAttributedStringsCache()

    func attributedTitle(appearance: CalendarRequestItemView.Appearance) -> NSAttributedString {
		let raw = self.title ?? ""
		return Self.attributedStringsCache.string(for: "title", raw: raw) {
			raw.attributed()
				.font(titleFont)
				.lineHeight(17)
				.foregroundColor(appearance.titleTextColor)
				.lineBreakMode(.byTruncatingTail)
				.string()
		}
    }

    func attributedSubtitle(appearance: CalendarRequestItemView.Appearance) -> NSAttributedString {
        let subtitle = self.subtitle ?? ""

		return Self.attributedStringsCache.string(for: "subtitle", raw: subtitle) {
			subtitle.attributed()
			   .font(subtitleFont)
			   .lineHeight(14)
			   .foregroundColor(appearance.subtitleTextColor)
			   .lineBreakMode(.byTruncatingTail)
			   .string()
		}
    }
}

extension UIFont {
	var topGapHeight: CGFloat {
		self.lineHeight - self.capHeight - self.descender - self.leading
	}
}


class NSAttributedStringsCache {
	private var cache = [String: [String: NSAttributedString]]()

	func string(for key: String, raw: String) -> NSAttributedString? {
		self.cache[key]?[raw]
	}

	func string(for key: String, raw: String, or compose: () -> NSAttributedString) -> NSAttributedString {
		if let string = self.cache[key]?[raw] {
			return string
		}
		
		let string = compose()
		self.set(for: key, raw: raw, attributed: string)

		return string
	}

	func set(for key: String, raw: String, attributed: NSAttributedString) {
		var subcache = self.cache[key] ?? [:]
		subcache[raw] = attributed
		self.cache[key] = subcache
	}
}
