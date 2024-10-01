import UIKit
import ChatSDK

final class ChatContainerViewController: UIViewController {
	weak var chatViewController: ChatViewController?

	var isHeaderViewHidden: Bool = false {
		didSet {
			self.headerViewContainer.isHidden = isHeaderViewHidden
		}
	}

	private lazy var mainVStack = with(UIStackView(.vertical)) { stack in
		stack.addArrangedSubviews(
			self.headerViewContainer,
			self.contentView
		)
	}

	private lazy var headerViewContainer = with(UIStackView(.vertical)) { stack in
		stack.addArrangedSubview(self.headerView)
		stack.addArrangedSubview(self.taskView)
		stack.backgroundColorThemed = Palette.shared.gray5

		stack.setContentHuggingPriority(.defaultHigh, for: .vertical)
		stack.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
	}

	private lazy var headerView = with(ChatNavigationBar()) { view in
		view.make(.height, .equal, 60)
		self.addSeparator(to: view)
	}

	private lazy var taskView = with(RequestListItemView()) { (view: RequestListItemView) in
		self.view.backgroundColorThemed =  view.appearance.backgroundColor
		self.addSeparator(to: view)
	}

	private lazy var contentView = UIView()

	private var latestChatHeaderViewContainerMaxY: CGFloat = 0.0
	private lazy var navigationViewController = with(UINavigationController()) { controller in
		controller.setNavigationBarHidden(true, animated: false)
		controller.willMove(toParent: self)
		self.addChild(controller)
		self.contentView.addSubview(controller.view)
		controller.view.make(.edges, .equalToSuperview)
		controller.didMove(toParent: self)
	}
	private lazy var taskPersistenceService = TaskPersistenceService.shared

	private let assistant: Assistant
	private var task: Task?
	private let onPhoneTap: (String) -> Void
	private let onDismiss: () -> Void

	var preFirstAppear: (() -> Void)?
	var onFirstAppear: (() -> Void)?

    init(
        assistant: Assistant,
        task: Task? = nil,
        chatViewController: ChatViewController?,
        paymentHandler: ((Order) -> Void)? = nil,
        onPhoneTap: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.chatViewController = chatViewController
		self.assistant = assistant
		self.task = task
		self.onPhoneTap = onPhoneTap
		self.onDismiss = onDismiss
		super.init(nibName: nil, bundle: nil)
		self.subscribeToNotifications()
	}

	@available (*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

		self.placeContent()

		self.updateChatNavigationBar()
		self.updateTaskView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.preFirstAppear?()
		self.preFirstAppear = nil
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.onFirstAppear?()
		self.onFirstAppear = nil
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		if self.isBeingDismissed {
			self.onDismiss()
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		self.adjustContentInsetsIfNeeded()
	}

	public func setContent(_ controller: UIViewController) {
		self.navigationViewController.setViewControllers([controller], animated: false)
	}

	private func subscribeToNotifications() {
		guard task != nil else {
			return
		}

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(updateTask),
			name: .tasksDidLoad,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.taskWasSuccessfullyPersisted(_:)),
			name: .taskWasSuccessfullyPersisted,
			object: nil
		)
	}

	private func updateChatNavigationBar() {
		self.headerView.setup(with: ChatHeaderViewModel(assistant: self.assistant))
		self.headerView.onPhoneTap = { [weak self] in
			guard let strongSelf = self else {
				return
			}
			let phone = UserDefaults.standard.string(forKey: "assistantPhoneNumber") ?? Config.assistantPhoneNumber
			strongSelf.onPhoneTap(phone)
		}
	}

	private func updateTaskView() {
		self.taskView.isHidden = self.task == nil
		guard let task = self.task else {
			return
		}

		let viewModel = RequestListItemViewModel(
			task: task,
			showsLatestMessage: false,
			showsPromoCategories: false,
			routesToTaskDetails: true,
			roundsCorners: false
		)

		self.taskView.setup(
			with: viewModel,
			onOrderViewTap: { [weak self] orderId in
				let order = task.ordersWaitingForPayment.first { $0.id == orderId }

				if let order = order {
					self?.requestPayment(for: order)
				}
			},
			onPromoCategoryTap: { categoryId in
				print("")
			}
		)
	}

	private func requestPayment(for order: Order) {
		NotificationCenter.default.post(
			name: .orderPaymentRequested,
			object: nil,
			userInfo: ["order": order]
		)
	}

	private func placeContent() {
		self.view.addSubview(self.mainVStack)
		self.mainVStack.make(.edges, .equalToSuperview)
	}

	private func addSeparator(to view: UIView) {
		let spacer = OnePixelHeightView {
			$0.backgroundColorThemed = Palette.shared.gray3
		}
		view.addSubview(spacer)
		spacer.make(.edges(except: .top), .equalToSuperview)
	}

	private func adjustContentInsetsIfNeeded() {
		let chatHeaderViewContainerMaxY = self.headerViewContainer.frame.maxY
		if chatHeaderViewContainerMaxY == self.latestChatHeaderViewContainerMaxY {
			return
		}

		func traverse(view: UIView, topMostView: UIView) -> Bool {
			if let scrollView = view as? UIScrollView {
				let convertedOrigin = view.convert(view.bounds, to: topMostView).origin
				if convertedOrigin == .zero {
					var insets = scrollView.contentInset
					insets.bottom = chatHeaderViewContainerMaxY

					scrollView.scrollIndicatorInsets = insets
					scrollView.contentInset = insets

					return true
				}

				return false
			}

			for child in view.subviews {
				if traverse(view: child, topMostView: topMostView) {
					return true
				}
			}

			return false
		}

		for child in self.view.subviews {
			if traverse(view: child, topMostView: self.view) {
				self.latestChatHeaderViewContainerMaxY = chatHeaderViewContainerMaxY
				break
			}
		}
	}

	@objc
	private func updateTask() {
		guard let task = self.task else {
			return
		}

		onGlobal {
			self.taskPersistenceService
				.task(with: task.taskID)
				.done(on: .main)
			{ [weak self] task in
				guard let self, let task else {
					return
				}
				self.task = task
				self.updateTaskView()
			}
		}
	}

	@objc
	private func taskWasSuccessfullyPersisted(_ notification: Notification) {
		guard let task = notification.userInfo?["task"] as? Task,
			  task.taskID == self.task?.taskID
		else {
			return
		}

		DispatchQueue.main.async {
			self.updateChatNavigationBar()
			self.updateTaskView()
		}
	}
}
