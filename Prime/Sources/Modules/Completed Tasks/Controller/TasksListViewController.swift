import ChatSDK
import UIKit
import XLPagerTabStrip

protocol TasksViewProtocol: ModalRouterSourceProtocol {
    func set(viewModel: CompletedTasksListViewModel)
}

final class TasksListViewController: UIViewController {
    private lazy var tasksListView: TasksListView = {
        let view = TasksListView()
        view.onSelectTaskByTaskId = { [weak self] taskID in
            self?.presenter.openChat(taskID: taskID)
        }
        view.onSelectTaskType = { [weak self] taskType in
            self?.presenter.filterTasks(by: taskType)
        }
        return view
    }()

    private let presenter: TasksListPresenterProtocol
    private let tabTitle: String

    init(presenter: TasksListPresenterProtocol, title: String) {
        self.presenter = presenter
        self.tabTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupList()
        self.presenter.didLoad()
    }

    // MARK: - Helpers

    private func setupList() {
        self.view.addSubview(self.tasksListView)
        self.tasksListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension TasksListViewController: TasksViewProtocol {
    func set(viewModel: CompletedTasksListViewModel) {
        self.tasksListView.update(viewModel: viewModel)
    }
}

extension TasksListViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: self.tabTitle)
    }
}
