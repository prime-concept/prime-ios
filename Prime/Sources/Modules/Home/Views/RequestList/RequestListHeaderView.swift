import UIKit

extension RequestListHeaderView {
    struct Appearance: Codable {
		var tintColor = Palette.shared.brandSecondary
        var titleTextColor = Palette.shared.gray0
		var titleFont = Palette.shared.primeFont.with(size: 20, weight: .bold)

		var countFont = Palette.shared.primeFont.with(size: 18, weight: .regular)

        var completedColor = Palette.shared.brandPrimary
		var completedFont = Palette.shared.primeFont.with(size: 18, weight: .regular)
    }
}

final class RequestListHeaderView: UICollectionReusableView, Reusable {
    private lazy var activeTasksTitleLabel: UILabel = {
        let label = UILabel()
		label.adjustsFontSizeToFitWidth = true
        label.attributedTextThemed = Localization.localize("home.requests.title").attributed()
            .foregroundColor(self.appearance.titleTextColor)
			.font(self.appearance.titleFont)
            .baselineOffset(1.0)
            .string()
        return label
    }()

    private lazy var activeTasksCountLabel = UILabel()

	private lazy var completedTasksCountLabel = UILabel { (label: UILabel) in
		label.adjustsFontSizeToFitWidth = true
		label.fontThemed = self.appearance.completedFont
		label.textColorThemed = self.appearance.completedColor
	}

	private lazy var completedTasksCountLabelContainer = self.completedTasksCountLabel.inset([2, 0, 0, 0])

    private lazy var completedTasksButton = UIStackView.horizontal (
		self.arrowImage,
		.hSpacer(5),
		self.completedTasksCountLabelContainer
    )

    private lazy var arrowImage = UIImageView { (imageView: UIImageView) in
        imageView.make(.width, .equal, 7)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "tasks_arrow_right")
        imageView.tintColorThemed = self.appearance.tintColor
		imageView.transform = CGAffineTransform(scaleX: -1, y: 1)
    }

    var onOpenPayFilter: (() -> Void)?
    var onOpenCompletedTasks: (() -> Void)?
    var onOpenGeneralChat: (() -> Void)?

    private var newRequestsView = NewRequestsView()

    private let appearance: Appearance

    override init(frame: CGRect) {
        self.appearance = Theme.shared.appearance()
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	func update(viewModel: RequestListHeaderViewModel) {
        let completedText = "task.isCompleted.temp"
		let completedAttributedText = completedText.localized.attributed()
			.font(self.appearance.completedFont)
			.foregroundColor(self.appearance.completedColor)
			.mutableString()

		let countAttributedText = " \(viewModel.completedCount)".attributed()
			.font(self.appearance.countFont)
			.foregroundColor(self.appearance.completedColor)
			.string()

		completedAttributedText.append(countAttributedText)

		self.completedTasksCountLabel.attributedTextThemed = completedAttributedText

		self.completedTasksButton.isHidden = viewModel.completedCount == 0

        self.activeTasksCountLabel.attributedTextThemed = "\(viewModel.activeCount)".attributed()
            .foregroundColor(self.appearance.completedColor)
            .primeFont(ofSize: 18, weight: .light, lineHeight: 22)
            .baselineOffset(1.0)
            .string()

        self.newRequestsView.setup(with: viewModel.latestMessageViewModel)
        self.newRequestsView.isHidden = true
    }
}

extension RequestListHeaderView: Designable {
    func setupView() {
		self.newRequestsView.isHidden = true
        self.newRequestsView.addTapHandler { [weak self] in self?.onOpenGeneralChat?() }
		self.completedTasksButton.addTapHandler { [weak self] in
			self?.onOpenCompletedTasks?()
		}
    }

    func addSubviews() {}

    func makeConstraints() {
		let activeTasksStack = UIStackView.horizontal(
			self.activeTasksTitleLabel, .hSpacer(5), self.activeTasksCountLabel.inset([0, 0, -3, 0])
		).inset([4, 0, 0, 0])

		let statisticsStack = UIStackView.horizontal(
			self.completedTasksButton, .hSpacer(growable: 5), activeTasksStack
		)
		statisticsStack.alignment = .center
		statisticsStack.make(.height, .equal, 32)

		let mainStack = UIStackView.vertical(
			statisticsStack,
			self.newRequestsView
		)

		mainStack.spacing = 13

		self.addSubview(mainStack)
		mainStack.make(.edges, .equalToSuperview, [0, 15, -6, -15])
    }
}
