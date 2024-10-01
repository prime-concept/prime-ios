import Foundation

protocol RequestCreationPresenterProtocol {
    func didLoad()
}

final class RequestCreationPresenter: RequestCreationPresenterProtocol {
    private let taskPersistenceService: TaskPersistenceServiceProtocol

    private var tasks: [Task] = []

    weak var controller: RequestCreationViewProtocol?

    init(taskPersistenceService: TaskPersistenceServiceProtocol) {
        self.taskPersistenceService = taskPersistenceService
    }

    func didLoad() {
        self.taskPersistenceService.retrieve().done { [weak self] tasks in
            guard let strongSelf = self else {
                return
            }
            strongSelf.tasks = tasks
            strongSelf.controller?.set(viewModel: strongSelf.makeViewModel(from: tasks))
        }
    }

    // MARK: - Private

    private func makeViewModel(from tasks: [Task]) -> RequestCreationViewModel {
        RequestCreationViewModel(
            uncompletedTasks: tasks.filter { !$0.completed },
            assistant: "assistant".localized,
            addTaskAction: { [weak self] type in
                self?.showCreationForm(for: type)
            },
            expandTaskAction: { [weak self] viewModel, itemView in
                self?.controller?.presentOrDismissExpandedRequestList(viewModel: viewModel, source: itemView)
            }
        )
    }

    private func showCreationForm(for taskType: TaskTypeObject) {
        guard let strongController = self.controller else {
            return
        }

        let assembly = DetailRequestCreationAssembly(typeID: taskType.id)
        let router = PushRouter(source: strongController, destination: assembly.make())
        router.route()
    }
}
