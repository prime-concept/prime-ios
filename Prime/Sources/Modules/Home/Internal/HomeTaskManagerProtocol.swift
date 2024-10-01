protocol HomeTaskManagerProtocol: AnyObject {
    func replaceAllTasks(with newTasks: [Task], feedbacks: [ActiveFeedback])
    func numberOfTasks(in list: HomeTaskManagerList) -> Int
    func tasks(from list: HomeTaskManagerList, where filter: (Task) -> Bool) -> [Task]
}

extension HomeTaskManagerProtocol {

    func hasTasks(in list: HomeTaskManagerList) -> Bool {
        numberOfTasks(in: list) > 0
    }

    func tasks(from list: HomeTaskManagerList) -> [Task] {
        tasks(from: list) { _ in true }
    }

    func task(from list: HomeTaskManagerList, where filter: (Task) -> Bool) -> Task? {
        tasks(from: list, where: filter).first
    }
}
