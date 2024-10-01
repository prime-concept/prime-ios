import UIKit

extension TaskDetailsViewController {
	struct Appearance: Codable {
		var backgroundColor = Palette.shared.gray5
		var navigationBackgroundColor = Palette.shared.gray5
		var navigationTintColor = Palette.shared.gray0
		var navigationFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
	}
}

final class TaskDetailsViewController: UIViewController {
	private let appearance: Appearance

	private var task: Task?
	private lazy var detailsView = TaskDetailsView()

    private lazy var headerView = with(LeftTitleCustomNavigationBar(rightButtonImageName: "share_icon",
                                                                    title: "task.detail.detail".localized)) { view in
        view.make(.height, .equal, 60)
    }

	init(appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		self.view = UIStackView.vertical(
            self.headerView,
			self.detailsView
		)
		self.view.backgroundColorThemed = self.appearance.backgroundColor
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		Notification.onReceive(.tasksDidLoad) { [weak self] in
			self?.updateOrders($0)
		}

		Notification.onReceive(UIApplication.willEnterForegroundNotification) { [weak self] _ in
			self?.willEnterForeground()
		}

		Notification.onReceive(.taskWasSuccessfullyPersisted) { [weak self] in
			self?.handleTaskPersisted(notification: $0)
		}
	}

	func update(with task: Task, refreshDetails: Bool = true) {
		self.task = task

		if refreshDetails {
			TaskDetailsService.shared.updateDetails(for: task)
		}

		let viewModel = TaskDetailsViewModel(task: task) { [weak self] url in
			SafariRouter.init(
				url: url,
				source: self?.topmostPresentedOrSelf,
				delegate: nil
			).route()
		}

		let shouldShowLoader = refreshDetails && (task.details.isEmpty && task.orders.isEmpty)

		if shouldShowLoader {
			self.showLoadingIndicator()
		}

		self.detailsView.update(with: viewModel)
		self.updateNavigationBar(title: viewModel.title)
	}

	private func updateNavigationBar(title: String) {
		self.navigationItem.title = title
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIView { view in
			view.make(.size, .equal, [22, 44])
			let imageView = UIImageView(image: UIImage(named: "request_details_back_arrow"))
			view.addSubview(imageView)
			imageView.make([.leading, .centerY], .equalToSuperview)
		})
		self.navigationItem.leftBarButtonItem?.customView?.addTapHandler { [weak self] in
			self?.dismiss(animated: true, completion: nil)
		}
	}

	private func updateOrders(_ notification: Notification) {
		guard var task = self.task,
			let tasks = notification.userInfo?["new_tasks"] as? [Task] else {
			return
		}

		guard let newTask = tasks.first(where: { $0.taskID == task.taskID }) else {
			return
		}

		task.orders = newTask.orders

		self.update(with: task, refreshDetails: false)
		self.hideLoadingIndicator()
	}

	private func willEnterForeground() {
		NotificationCenter.default.post(name: .tasksUpdateRequested, object: nil)
	}

	private func handleTaskPersisted(notification: Notification) {
		let task = notification.userInfo?["task"] as? Task

		guard let task = task, task.taskID == self.task?.taskID else {
			return
		}

		self.update(with: task, refreshDetails: false)
		self.hideLoadingIndicator()
	}
}
