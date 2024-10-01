import UIKit
import SnapKit

extension RequestListItemView {
    struct Appearance: Codable {
        var separatorColor = Palette.shared.gray3
        var bottomContainerBackgroundColor = Palette.shared.gray5
        var backgroundColor = Palette.shared.gray5
        var cornerRadius: CGFloat = 10
		var regularHeight: CGFloat = 52
		var expandedHeight: CGFloat = 99
    }
}

final class RequestListItemView: UIView {
	private lazy var containerStackView = with(UIStackView()) { stack in
		stack.axis = .vertical
	}

	private lazy var headerView = RequestItemMainView()
	private lazy var lastMessageView = RequestItemLastMessageView()
	private lazy var feedbackView = DefaultRequestItemFeedbackView()
	private lazy var completedTaskFeedbackView = CompletedRequestItemFeedbackView()

	private func addSeparator(to view: UIView) {
        let separator = OnePixelHeightView()
		separator.backgroundColorThemed = self.appearance.separatorColor

		view.addSubview(separator)
		separator.make(.edges(except: .bottom), .equalToSuperview)
    }

    private lazy var buttonsView = with(PaymentButtonsView()) { view in
        view.backgroundColorThemed = self.appearance.bottomContainerBackgroundColor
        view.clipsToBounds = true
    }

    private(set) var appearance: Appearance

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

	override var intrinsicContentSize: CGSize {
		CGSize(
			width: UIScreen.main.bounds.width,
			height: self.buttonsView.isHidden
				? self.appearance.regularHeight
				: self.appearance.expandedHeight
		)
	}

    func setup(
		with viewModel: RequestListItemViewModel,
		onOrderViewTap: ((Int) -> Void)?,
		onPromoCategoryTap: ((Int) -> Void)?
	) {
		self.setupTapHandlers(with: viewModel)

		self.buttonsView.onOrderTap = onOrderViewTap
		self.buttonsView.onPromoCategoryTap = onPromoCategoryTap

        self.headerView.setup(with: viewModel.headerViewModel)

		self.lastMessageView.isHidden = true

        if let lastMessage = viewModel.lastMessageViewModel {
            self.lastMessageView.setup(with: lastMessage)
            self.lastMessageView.isHidden = false
        }

		self.feedbackView.isHidden = true
		self.completedTaskFeedbackView.isHidden = true

		if let feedback = viewModel.feedbackViewModel {
			let feedbackView: RequestItemFeedbackView
			feedbackView = feedback.taskCompleted ? self.completedTaskFeedbackView : self.feedbackView

			feedbackView.isHidden = false
            
            if feedback.taskCompleted {
                lastMessageView.isHidden = true
            }

			feedbackView.setup(with: feedback)
		}

        // NOTE @kvld: сепараторы должны быть частью description блока,
        // потому что у него есть разные состояния с разным фоном и он используется в блоке с новым обращением

		self.buttonsView.set(
			orders: viewModel.orders,
			promoCategories: viewModel.promoCategories
		)

		let bottomContainerHidden = viewModel.orders.isEmpty && viewModel.promoCategories.isEmpty
        self.buttonsView.isHidden = bottomContainerHidden

		let cornerRadius = viewModel.roundsCorners ? self.appearance.cornerRadius : 0
		
		self.layer.cornerRadius = cornerRadius
		self.headerView.layer.cornerRadius = cornerRadius

		self.invalidateIntrinsicContentSize()
	}

	private func setupTapHandlers(with viewModel: RequestListItemViewModel) {
		var userInfo = [String: Any]()
		userInfo["taskId"] = viewModel.headerViewModel.taskID
		userInfo["task"] = viewModel.headerViewModel.task

		var isSingleTapZone = UserDefaults[bool: "taskTapAreasEnabled"] == false
		isSingleTapZone = isSingleTapZone || viewModel.lastMessageViewModel == nil

		[self.feedbackView, self.completedTaskFeedbackView].forEach {
			$0.addTapHandler {
				Notification.post(.didTapOnFeedback, userInfo: userInfo)
			}
		}

		if isSingleTapZone {
			self.containerStackView.addTapHandler {
				Notification.post(.didTapOnTaskMessage, userInfo: userInfo)
			}
			return
		}

		self.headerView.addTapHandler {
			Notification.post(.didTapOnTaskHeader, userInfo: userInfo)
		}

		self.lastMessageView.addTapHandler {
			Notification.post(.didTapOnTaskMessage, userInfo: userInfo)
		}
	}
}

extension RequestListItemView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.layer.cornerRadius = self.appearance.cornerRadius
        self.clipsToBounds = true

        self.headerView.clipsToBounds = true
        self.headerView.layer.cornerRadius = self.appearance.cornerRadius
        self.headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    func addSubviews() {
		self.containerStackView.addArrangedSubviews(
			self.headerView,
			UIStackView.vertical(
				self.lastMessageView,
				self.completedTaskFeedbackView
			),
			self.buttonsView,
			self.feedbackView
		)

		self.addSeparator(to: self.lastMessageView)
		self.addSeparator(to: self.completedTaskFeedbackView)
		self.addSeparator(to: self.feedbackView)
		self.addSeparator(to: self.buttonsView)

		self.addSubview(self.containerStackView)
    }

    func makeConstraints() {
		self.containerStackView.make(.edges(except: .bottom), .equalToSuperview)
		self.containerStackView.make(.bottom, .equalToSuperview, priority: .defaultHigh)

		self.buttonsView.make(.hEdges, .equalToSuperview)
		self.buttonsView.make(.height, .equal, 46)
    }
}
