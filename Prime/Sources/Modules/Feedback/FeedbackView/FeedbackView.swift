import UIKit

extension FeedbackView {
	struct Appearance: Codable {
		var separatorColor = Palette.shared.gray3
		var backgroundColor = Palette.shared.gray5

		var titleColor = Palette.shared.gray0
		var titleFont = Palette.shared.smallTitle
	}
}

class FeedbackView: UIView {
	private let appearance: Appearance

	private var onRatingChanged: ((Int) -> Void)?
	private var onSubmit: ((Int, [Int], String?) -> Void)?
	private var onFinish: (() -> Void)?
    
    weak var delegate: (any FeedbackViewDelegate)?

	private var state: FeedbackViewModel.State? {
		didSet {
			self.updateState()
		}
	}
    
    private let alreadyRatedStars: Int?
	
	init(appearance: Appearance = Theme.shared.appearance(), alreadyRatedStars: Int? = nil) {
		self.appearance = appearance
        self.alreadyRatedStars = alreadyRatedStars
		super.init(frame: .zero)

		self.placeSubviews()
		_ = self.keyboardTracker
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private lazy var keyboardTracker = PrimeKeyboardHeightTracker(
		view: self, animationsEnabled: true
	) { [weak self] height in
		guard let self = self else { return }

		var bottomConstant = height
		var scrollToBottom = false
		let safeAreaBottom = self.safeAreaInsets.bottom

		if height > 100 {
			scrollToBottom = true
			bottomConstant -= safeAreaBottom
		} else {
			bottomConstant = 0
		}

		self.mainStackBottom?.constant = -bottomConstant
		self.actionButtonBottom?.constant = -bottomConstant

		if scrollToBottom {
			self.mainStack.scroll(to: .bottom)
		}
	}

	private lazy var titleLabel = UILabel { (label: UILabel) in
		label.textColorThemed = self.appearance.titleColor
		label.fontThemed = self.appearance.titleFont
		label.lineBreakMode = .byWordWrapping
		label.numberOfLines = 0

		label.textAlignment = .center
	}

	private lazy var titleLabelContainer = self.titleLabel.inset { container in
		self.titleLabel.make(.vEdges, .equalToSuperview, [10, -20])
		self.titleLabel.make(.centerX, .equalToSuperview)
		container.make(.width, .greaterThanOrEqual, to: self.titleLabel)

		let separator = self.makeSeparator()
		container.addSubview(separator)
		separator.make(.edges(except: .top), .equalToSuperview)
	}

	private lazy var detailsViewContainer = self.detailsView.inset { container in
		let separator = self.makeSeparator()
		container.addSubview(separator)
		separator.make(.edges(except: .bottom), .equalToSuperview)

		self.detailsView.make(.edges, .equalToSuperview, [30, 15, 0, -15])
	}

	private lazy var taskTopSpacer = UIView()

    private lazy var taskRatingView = with(FeedbackRatingView(alreadyRatedStars: self.alreadyRatedStars)) { header in
		header.onRatingSet = { [weak self] rating in
			self?.detailsView.chipsControl.selection = []
			self?.onRatingChanged?(rating)
		}
	}

	private lazy var taskRatingViewContainer = self.taskRatingView.inset([20, 0, -20, 0])

	private func makeSeparator() -> UIView {
		with(UIView.vSpacer(0.5)) { view in
			view.backgroundColorThemed = self.appearance.separatorColor
		}
	}

	private lazy var detailsView = FeedbackDetailsView()
	private lazy var successView = FeedbackSuccessView()

	private var mainStackBottom: NSLayoutConstraint?
	private var actionButtonBottom: NSLayoutConstraint?

	private lazy var actionButton = with(FilledActionButton()) {
		$0.make(.height, .equalToSuperview, 44)

		$0.addTapHandler { [weak self] in
			self?.didTapActionButton()
		}
	}

	private lazy var actionButtonContainer = UIView { view in
		view.backgroundColorThemed = self.appearance.backgroundColor
		view.addSubview(self.actionButton)

		self.actionButton.make(.edges, .equalToSuperview, [10, 15, -10, -15])
	}

	private lazy var mainStack = ScrollableStack(
		.vertical,
		arrangedSubviews: [
			self.titleLabelContainer,

			self.taskTopSpacer,
			self.taskRatingViewContainer,

			self.detailsViewContainer
		]
	)

	private func placeSubviews() {
		self.backgroundColorThemed = self.appearance.backgroundColor
		self.mainStack.keyboardDismissMode = .onDrag

		self.addSubview(self.successView)
		self.successView.make(.edges, .equalToSuperview)

		self.addSubview(self.mainStack)
		self.mainStackBottom = self.mainStack.make(.edges, .equal, to: self.safeAreaLayoutGuide)[2]

		self.titleLabelContainer.make(.width, .equalToSuperview)
		self.detailsViewContainer.make(.width, .equalToSuperview)

		self.addSubview(self.actionButtonContainer)
		self.actionButtonContainer.make(.hEdges, .equalToSuperview)

		self.actionButtonBottom = self.actionButtonContainer.make(.bottom, .equal, to: self.safeAreaLayoutGuide)

		self.detailsViewContainer.isHidden = true
		self.successView.alpha = 0
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		self.layoutViewIfNeeded()
	}
	
	func setup(with viewModel: FeedbackViewModel) {
		self.state = viewModel.state
		self.titleLabel.textThemed = viewModel.title

		with(self.taskRatingView) {
			$0.imageView.image = viewModel.taskIcon?.withRenderingMode(.alwaysTemplate)
			$0.taskDateLabel.textThemed = viewModel.taskDate
			$0.taskTitleLabel.textThemed = viewModel.taskName
		}

		with(self.taskRatingView.starsContainer) {
			$0.worstSubscriptLabel.text = viewModel.worstSubscription
			$0.bestSubscriptLabel.text = viewModel.bestSubscription
		}

		with(self.detailsView) {
			$0.complaintTitleLabel.text = viewModel.complaintsTitle
			$0.complaintSubtitleLabel.text = viewModel.complaintsSubtitle
			
			$0.chipsControl.titles = viewModel.complaints
			$0.complaintTextView.placeholder = viewModel.feedbackPlaceholder
		}

		self.successView.titleLabel.textThemed = viewModel.successTitle
		self.successView.subtitleLabel.textThemed = viewModel.successSubtitle

		self.actionButton.title = viewModel.actionButtonTitle

		self.onSubmit = viewModel.onSubmit
		self.onRatingChanged = viewModel.onRatingChanged
	}

	private func didTapActionButton() {
		if self.state == .initial {
			return
		}

		if self.state == .success {
			self.onFinish?()
			return
		}

		self.endEditing(true)

		delay(0.3) {
			self.onSubmit?(
				self.taskRatingView.rating,
				self.detailsView.chipsControl.selection,
				self.detailsView.complaintTextView.text
			)
		}
	}

	private func updateState() {
		guard let state = self.state else {
			return
		}

		self.setNeedsLayout()

		let starsControl = self.taskRatingView.starsContainer.starsControl

		self.actionButtonContainer.isHidden = true

        switch state {
        case .initial:
            starsControl.minRating = 0
        case .details:
            starsControl.minRating = 1
            
            UIView.animate(withDuration: 0.3) {
                self.showDetailsView()
                self.showActionButton()
            }
        case .success:
            UIView.animate(withDuration: 0.3) {
                self.showSuccessView()
            } completion: { _ in
                self.delegate?.feedbackViewDidPresentSuccessView(self)
            }
        }
	}

	private func showActionButton() {
		self.actionButtonContainer.isHidden = false

		let insetBottom = self.actionButtonContainer.sizeFor(
			width: self.mainStack.bounds.width
		).height

		self.mainStack.contentInset.bottom = insetBottom + 69
		self.mainStack.scrollIndicatorInsets.bottom = insetBottom
	}

	private func showDetailsView() {
		self.taskTopSpacer.isHidden = true

		self.detailsViewContainer.isHidden = false
		self.detailsViewContainer.alpha = 1
	}

	private func showSuccessView() {
		self.mainStack.alpha = 0
		self.successView.alpha = 1
	}

	private func layoutViewIfNeeded() {
		let stack = self.mainStack.stackView
		let height = stack.sizeFor(width: self.bounds.width).height + 10
		stack.snp.remakeConstraints {
			$0.height.equalTo(height).priority(UILayoutPriority.defaultLow)
		}

		let titleHeight = self.titleLabelContainer.sizeFor(width: self.bounds.width).height
		let ratingHeight = self.taskRatingViewContainer.sizeFor(width: self.bounds.width).height

		let freeHeight = self.bounds.height - titleHeight - ratingHeight
		let topSpacerHeight = (freeHeight * 200 / 259) / 2
		self.taskTopSpacer.snp.remakeConstraints { $0.height.equalTo(topSpacerHeight) }
	}
}
