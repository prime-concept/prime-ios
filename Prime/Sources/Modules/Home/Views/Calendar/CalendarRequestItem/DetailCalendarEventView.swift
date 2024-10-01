import UIKit

extension DetailCalendarEventView {
	struct Appearance: Codable {
		var titleTextColor = Palette.shared.gray0
		var subtitleTextColor = Palette.shared.gray1
		var dateTextColor = Palette.shared.gray0

		var backgroundColor = Palette.shared.gray5
		var logoBorderWidth: CGFloat = 0.5
		var logoBorderColor = Palette.shared.brandSecondary

		var tintColor = Palette.shared.brandSecondary
	}
}

final class DetailCalendarEventView: UIView {
	static let defaultHeight: CGFloat = 49

	private var spacersRatioConstraint: NSLayoutConstraint?

	private lazy var logoView = TaskInfoTypeView()

	private lazy var dateSpacer: UIView = .vSpacer(4)

	private lazy var titleLabel = UILabel()
	private lazy var subtitleLabel = UILabel()
	private lazy var dateLabel = UILabel()

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
    
    var isExpanded: Bool = false {
         didSet {
             let expandedImage = UIImage(named: "expanded_calendar_arrow_up")
             let collapsedImage = UIImage(named: "expanded_calendar_arrow_down")
             self.expansionImageView.image = isExpanded ? expandedImage : collapsedImage
         }
     }

    var onExpandTap: ((Bool) -> Void)?
    
    lazy var filesToggleView: UIView = {
        var view = UIView()
        view.backgroundColorThemed = Palette.shared.brandSecondary.withAlphaComponent(0.05)
        view.clipsToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 6.0
        view.layer.borderColorThemed = Palette.shared.brandSecondary

		let title = UILabel()
		title.text = "expandingCalendar.files".localized
		title.textAlignment = .left
		title.fontThemed = Palette.shared.captionReg
		title.textColorThemed = Palette.shared.gray0

		let collapsedImage = UIImage(named: "expanded_calendar_arrow_down")
		self.expansionImageView.image = collapsedImage?.withRenderingMode(.alwaysTemplate)
		self.expansionImageView.tintColorThemed = Palette.shared.brandSecondary

		view.addSubviews(title, expansionImageView)

		title.snp.makeConstraints { make in
			make.leading.equalToSuperview().offset(10)
			make.trailing.equalTo(expansionImageView.snp.leading)
			make.centerY.equalToSuperview()
		}

		self.expansionImageView.snp.makeConstraints { make in
			make.width.height.equalTo(24)
			make.trailing.equalToSuperview().offset(-5)
			make.top.equalToSuperview().offset(5)
			make.bottom.equalToSuperview().offset(-5)
		}

		let spacer1 = UIView.vSpacer(growable: 0)
		let spacer2 = UIView.vSpacer(growable: 0)

		let vStack = UIStackView.vertical(
			spacer1,
			view,
			spacer2
		)

		spacer1.make(.height, .equal, to: spacer2)

		vStack.addTapHandler { [weak self] in
			guard let self else { return }
			self.isExpanded.toggle()
			self.onExpandTap?(self.isExpanded)
		}

        return vStack
    }()
    
    lazy var expansionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

	private static let cache = NSAttributedStringsCache()
    
	func setup(with viewModel: CalendarRequestItemViewModel) {
		self.setup(
			task: viewModel.task,
			title: viewModel.title,
			subtitle: viewModel.location,
			date: viewModel.formattedDate,
			image: viewModel.logo
		)
	}

	// MARK: - Helpers
	private lazy var taskIdLabel = UILabel { (label: UILabel) in
		label.font = .systemFont(ofSize: 48)
		label.textColor = .red
		label.alpha = 0.3
		label.textAlignment = .center
		label.adjustsFontSizeToFitWidth = true

		self.addSubview(label)
		label.make(.center, .equalToSuperview)
		label.make(.hEdges, .equalToSuperview, [10, -10])
	}

	private func setup(
		task: Task!,
		title: String?,
		subtitle: String?,
		date: String?,
		image: UIImage?
	) {
		let title = title ?? ""
		let subtitle = subtitle ?? ""
		let date = date ?? ""

		if let task = task {
			let taskId = task.taskID
			self.taskIdLabel.text = "\(taskId) (\(task.events.count))[\(task.attachedFiles.count)]"
			self.taskIdLabel.isHidden = !UserDefaults[bool: "showsTaskIdsOnTasks"]
		} else {
			self.taskIdLabel.isHidden = true
		}

		self.filesToggleView.isHidden = task.attachedFiles.isEmpty

		self.titleLabel.isHidden = title.isEmpty
		self.subtitleLabel.isHidden = subtitle.isEmpty
		
		self.dateLabel.isHidden = date.isEmpty
		self.dateSpacer.isHidden = self.dateLabel.isHidden

		if self.titleLabel.text != title  {
			self.titleLabel.attributedTextThemed = Self.cache.string(for: "titleLabel", raw: title) {
				title.attributed()
					.foregroundColor(appearance.titleTextColor)
					.primeFont(ofSize: 14, lineHeight: 13)
					.lineBreakMode(.byTruncatingTail)
					.string()
			}
		}

		if self.subtitleLabel.text != subtitle {
			self.subtitleLabel.attributedTextThemed = Self.cache.string(for: "subtitleLabel", raw: subtitle) {
				subtitle.attributed()
					.foregroundColor(appearance.subtitleTextColor)
					.primeFont(ofSize: 11, lineHeight: 13)
					.lineBreakMode(.byTruncatingTail)
					.string()
			}
		}

		if self.dateLabel.text != date {
			self.dateLabel.attributedTextThemed = Self.cache.string(for: "dateLabel", raw: date) {
				date.attributed()
					.foregroundColor(appearance.dateTextColor)
					.primeFont(ofSize: 11, weight: .medium, lineHeight: 13)
					.lineBreakMode(.byTruncatingTail)
					.string()
			}
		}

		self.logoView.set(image: image)
		self.subtitleLabel.isHidden = subtitle.isEmpty
	}

	private func setupTaskDetails(for task: Task?) {
		guard let task = task else {
			return
		}

		self.addTapHandler {
			let sourceViewController = self.viewController?.topmostPresentedOrSelf
			let taskDetailsViewController = TaskDetailsViewController()
			taskDetailsViewController.update(with: task)
			sourceViewController?.presentModal(controller: taskDetailsViewController)
		}
	}
}

extension DetailCalendarEventView: Designable {
	func setupView() {
		self.backgroundColorThemed = self.appearance.backgroundColor

		self.logoView.layer.borderWidth = self.appearance.logoBorderWidth
		self.logoView.layer.borderColorThemed = self.appearance.logoBorderColor
	}

	func addSubviews() {
		let contentHStack = UIStackView()
		contentHStack.axis = .horizontal
		contentHStack.spacing = 10

		let logoStack = with(UIStackView()) { stack in
			stack.axis = .vertical
			let spacer1 = UIView.vSpacer(growable: 0)
			let spacer2 = UIView.vSpacer(growable: 0)
			stack.addArrangedSubviews(
				spacer1,
				self.logoView,
				spacer2
			)
			spacer2.make(.height, .equal, to: spacer1)
		}

		let labelsVStack = UIStackView { (vStack: UIStackView) in
			vStack.axis = .vertical
			vStack.alignment = .leading

			let spacer1 = UIView.vSpacer(growable: 0)
			let spacer2 = UIView.vSpacer(growable: 0)

			vStack.addArrangedSubviews(
				spacer1,
				self.titleLabel,
				.vSpacer(4),
				self.subtitleLabel,
				self.dateSpacer,
				self.dateLabel,
				spacer2
			)

			spacer2.make(.height, .equal, to: spacer1)
		}

		contentHStack.addArrangedSubviews (
			logoStack.inset([4, 4, -4, -4]),
			labelsVStack,
			self.filesToggleView
		)

        self.addSubview(contentHStack)
        contentHStack.make(.edges, .equalToSuperview)
	}

	func makeConstraints() {
		self.logoView.make(.size, .equal, [36, 36], priorities: [.init(999)])

		[self.titleLabel, self.dateLabel, self.subtitleLabel].forEach {
			$0.setContentHuggingPriority(.required, for: .vertical)
		}

		self.make(.height, .equal, Self.defaultHeight)
	}
}

