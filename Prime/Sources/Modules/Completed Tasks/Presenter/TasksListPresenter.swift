import Foundation
import PromiseKit
import ChatSDK

protocol TasksListPresenterProtocol {
    func didLoad()
	func openChat(taskID: Int)
    func filterTasks(by type: TaskTypeEnumeration)
}

enum TasksListType: String {
    case waitingForPayment = "tasksList.type.waitingForPayment"
    case completed = "tasksList.type.completed"
	case all = "tasksList.type.all"
}

final class TasksListPresenter: TasksListPresenterProtocol {
    weak var controller: TasksViewProtocol?
    private let taskPersistenceService: TaskPersistenceServiceProtocol
    private let analyticsReporter: AnalyticsReportingServiceProtocol
    private let listType: TasksListType

    private var tasks: [Task] = []
    private var viewModel: CompletedTasksListViewModel?

	@PersistentCodable(fileName: "Home-Feedbacks")
	private var activeFeedbacks = [ActiveFeedback]()

    init(
        taskPersistenceService: TaskPersistenceServiceProtocol,
        analyticsReporter: AnalyticsReportingServiceProtocol,
        tasksListType: TasksListType = .waitingForPayment
    ) {
        self.taskPersistenceService = taskPersistenceService
        self.analyticsReporter = analyticsReporter
        self.listType = tasksListType
    }

    // MARK: - Public APIs

    func didLoad() {
        self.loadList()
    }

	func openChat(taskID taskId: Int) {
        guard let viewModel = viewModel,
			  let task = viewModel.completedTaskViewModels.first(where: { $0.task.taskID == taskId })?.task,
              let controller = self.controller,
              let assistant = task.responsible,
              var chatParams = ChatAssembly.ChatParameters.make(for: task,
                                                                assistant: assistant,
                                                                activeFeedbacks: self.activeFeedbacks) else {
            return
        }

		var inputDecorations = [UIView]()
		if let feedback = self.activeFeedbacks.first(where: { $0.objectId == taskId.description }) {
			inputDecorations.append(
				DefaultRequestItemFeedbackView.standalone(taskId: task.taskID, insets: [0, 5, 0, 0]) { [weak self] in
					guard let self else { return }
					self.analyticsReporter.didTapOnFeedbackInChat(taskId: task.taskID, feedbackGuid: feedback.guid^)
				}
			)
		}
		
        let chatViewControler = ChatAssembly.makeChatContainerViewController(
            with: chatParams,
			inputDecorationViews: inputDecorations
        )

        let router = ModalRouter(
            source: controller,
            destination: chatViewControler,
            modalPresentationStyle: .pageSheet
        )
        router.route()
    }

    func filterTasks(by type: TaskTypeEnumeration) {
        let viewModel = CompletedTasksListViewModel(
            tasks: self.tasks,
            listType: self.listType,
            filterBy: type
        )
        self.viewModel = viewModel
        self.controller?.set(viewModel: viewModel)
    }

    // MARK: - Private APIs

    private func loadList() {
        self.taskPersistenceService.retrieve().done { tasks in
			var tasks = tasks
			if UserDefaults[bool: "tasksUnreadOnly"] {
				tasks = tasks.filter{ $0.unreadCount > 0 }
			}

			switch self.listType {
				case .waitingForPayment:
					self.tasks = tasks.filter { !$0.completed && $0.isWaitingForPayment }
				case .completed:
					self.tasks = tasks.filter(\.completed)
				case .all:
					self.tasks = tasks
			}

			let viewModel = CompletedTasksListViewModel(
				tasks: self.tasks,
				listType: self.listType
			) { [weak self] paymentLink in
				if let paymentLink = paymentLink {
					let router = SafariRouter(url: paymentLink, source: self?.controller)
					router.route()
					self?.analyticsReporter.tappedPayment()
				}
			}
			self.viewModel = viewModel
			self.controller?.set(viewModel: viewModel)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) taskPersistenceService.retrieve failed",
					parameters: error.asDictionary
				)
		}
    }
}
