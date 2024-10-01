import UIKit

extension HomeView {
	struct Appearance: Codable {
		static let internetUnreachableIcon: UIImage? = UIImage(named: "no_internet")
		static let serverUnreachableText = "home.server.unreachable".localized
		static let internetUnreachableText = "home.internet.unreachable".localized

		var internetUnreachableColor = Palette.shared.danger
		var serverUnreachableColor = Palette.shared.attention

		var unreachableAlertCornerRadius: CGFloat = 10
		var unreachableAlertHeight: CGFloat = 36
		var unreachableAlertTintColor = Palette.shared.gray5
		var unreachableAlertFont = Palette.shared.primeFont.with(size: 12, weight: .regular)

		var backgroundColor = Palette.shared.gray4
	}
}

final class HomeView: UIView {
	private let appearance: Appearance

	private lazy var floatingControlsView = FloatingControlsView.shared

    private(set) lazy var headerView: HomeHeaderView = {
        let view = HomeHeaderView()
        view.onTapProfile = { [weak self] in
            self?.onTapProfile?()
        }
		view.isHidden = true
        return view
    }()

    private(set) lazy var calendarView: HomeCalendarView = {
        let view = HomeCalendarView()
		view.onExpandButton = { [weak self] date in self?.openDetailCalendar?(date) }
        return view
    }()

    private(set) lazy var requestListView: RequestListView = {
        let view = RequestListView()
        view.onListScroll = { [weak self] listScrolledDown in
            self?.calendarView.updateLayout(shouldMinimize: listScrolledDown)
        }
        view.onRefreshList = { [weak self] in
            self?.onRefreshList?()
        }
        view.onEmptyListTap = { [weak self] in
            self?.onEmptyListTap?()
        }
		view.onPaymentTap = { [weak self] orderId in
			self?.onOrderTap?(orderId)
		}
		view.onPromoCategoryTap = { [weak self] category in
			self?.onPromoCategoryTap?(category)
		}
        return view
    }()

    var containerView: UIView? {
        self.calendarView
    }

    var containerContentView: UIView? {
        self.calendarView.containerView
    }

    var onTapProfile: (() -> Void)?
    var openDetailCalendar: ((Date) -> Void)?
    var onRefreshList: (() -> Void)?
    var onEmptyListTap: (() -> Void)?

    var onOrderTap: ((Int) -> Void)? {
        didSet {
            headerView.onOrderTap = onOrderTap
        }
    }
	
    var onOpenGeneralChat: (() -> Void)? {
        didSet {
            requestListView.onOpenGeneralChat = self.onOpenGeneralChat
        }
    }
    var onOpenPayFilter: (() -> Void)? {
        didSet {
            requestListView.onOpenPayFilter = self.onOpenPayFilter
        }
    }
    var onOpenCompletedTasks: (() -> Void)? {
        didSet {
            requestListView.onOpenCompletedTasks = self.onOpenCompletedTasks
        }
    }
	var onPromoCategoryTap: ((Int) -> Void)?

	private lazy var contentStackView = UIStackView.vertical()
	private lazy var internetUnreachableAlert = self.makeServerUnreachableView(
		backgroundColor: self.appearance.internetUnreachableColor,
		text: Appearance.internetUnreachableText,
		icon: Appearance.internetUnreachableIcon
	)

	private lazy var serverUnreachableAlert = self.makeServerUnreachableView(
		backgroundColor: self.appearance.serverUnreachableColor,
		text: Appearance.serverUnreachableText
	)

	init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance

        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()

		Notification.onReceive(.networkReachabilityChanged) { [weak self] _ in
			self?.updateNetworkAlertsVisibility()
		}

		Notification.onReceive(.networkEventOccured) { [weak self] notification in
			self?.updateNetworkAlertsVisibility(error: notification.userInfo?["error"] as? Error)
		}
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(viewModel: HomeViewModel) {
        self.headerView.set(data: viewModel.paymentItems)
        self.requestListView.update(viewModel: viewModel)
        self.calendarView.update(with: viewModel.calendarItems)
        self.floatingControlsView.setUnreadCount(viewModel.generalChatUnreadMessagesCount)
    }

	override func layoutSubviews() {
		super.layoutSubviews()
		self.floatingControlsView.toFront()
	}

	private func makeServerUnreachableView(
		backgroundColor: ThemedColor,
		text: String,
		icon: UIImage? = nil
	) -> UIView {
		UIView { view in
			view.backgroundColorThemed = backgroundColor
			view.make(.height, .equal, self.appearance.unreachableAlertHeight)
			view.layer.cornerRadius = self.appearance.unreachableAlertCornerRadius
			let stack = UIStackView { (stackView: UIStackView) in
				stackView.axis = .horizontal
				stackView.alignment = .center
				stackView.spacing = 5
				stackView.addArrangedSubviews(
					UIImageView { (imageView: UIImageView) in
						imageView.tintColorThemed = self.appearance.unreachableAlertTintColor
						imageView.image = icon
						imageView.isHidden = icon == nil
					},
					UILabel { (label: UILabel) in
						label.textColorThemed = self.appearance.unreachableAlertTintColor
						label.fontThemed = self.appearance.unreachableAlertFont
						label.text = text
					}
				)
			}

			view.addSubview(stack)
			stack.make(.height, .equalToSuperview)
			stack.make(.center, .equalToSuperview)
		}
	}

	private var mayUpdateNetworkAlertsVisibility = true

	private func updateNetworkAlertsVisibility(error: Error? = nil) {
		guard self.mayUpdateNetworkAlertsVisibility else {
			return
		}

		var internetAlertHidden = true
		var serverAlertHidden = true

		defer {
			if !internetAlertHidden {
				DebugUtils.shared.log(sender: self, "WILL SHOW NO INTERNET ALERT! (RED)")
			}

			if !serverAlertHidden {
				DebugUtils.shared.log(sender: self, "WILL SHOW SERVER UNREACHABLE ALERT! (YELLOW)")
			}

			self.internetUnreachableAlert.isHidden = internetAlertHidden
			self.serverUnreachableAlert.isHidden = serverAlertHidden

			self.mayUpdateNetworkAlertsVisibility = false

			UIView.animate(withDuration: 0.3, animations: {
				self.internetUnreachableAlert.alpha = internetAlertHidden ? 0 : 1
				self.serverUnreachableAlert.alpha = serverAlertHidden ? 0 : 1
				self.layoutIfNeeded()
			}) { _ in
				self.mayUpdateNetworkAlertsVisibility = true
			}
		}

		guard NetworkMonitor.shared.isConnected else {
			internetAlertHidden = false
			return
		}

		guard let _ = error else {
			return
		}

		serverAlertHidden = false
	}
}

extension HomeView: Designable {
    func setupView() {
		self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
		self.contentStackView.addArrangedSubviews(
			self.headerView,
			self.calendarView,
			self.internetUnreachableAlert,
			self.serverUnreachableAlert,
			self.requestListView
		)

		self.internetUnreachableAlert.isHidden = true
		self.serverUnreachableAlert.isHidden = true

		self.addSubview(self.contentStackView)
		self.addSubview(self.floatingControlsView)
    }

    func makeConstraints() {
		self.contentStackView.spacing = 15
		self.contentStackView.alignment = .center

		self.contentStackView.make(.top, .equal, to: self.safeAreaLayoutGuide, +10)
		self.contentStackView.make(.edges(except: .top), .equalToSuperview)

		[self.headerView, self.requestListView].forEach {
			$0.make(.width, .equalToSuperview)
		}

		[self.calendarView, self.internetUnreachableAlert, self.serverUnreachableAlert].forEach {
			$0.make(.width, .equalToSuperview, -30)
		}
		self.floatingControlsView.make(.edges, .equalToSuperview)
    }
}
