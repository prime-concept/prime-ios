// MARK: - Manager

final class HomeTaskManager {

    weak var delegate: (any HomeTaskManagerDelegate)?

    @ThreadSafe var tasks = [Task]()
    @ThreadSafe var activeTasksIndices = [Int]()
    @ThreadSafe var displayableTasksIndices = [Int]()
    
}

// MARK: - HomeTaskManagerProtocol

extension HomeTaskManager: HomeTaskManagerProtocol {

    func replaceAllTasks(with newTasks: [Task], feedbacks: [ActiveFeedback]) {
        tasks = newTasks

        activeTasksIndices = indicesForActiveTasks(in: &tasks)
        displayableTasksIndices = indicesForDisplayableTasks(
            in: &tasks,
            feedbackObjectIDs: feedbackObjectIDs(from: feedbacks)
        )

        if hasTasks(in: .displayable) {
            delegate?.taskManagerHasDisplayableTasks(self)
        }
    }

    private func indicesForActiveTasks(in tasks: inout [Task]) -> [Int] {
        tasks
            .enumerated()
            .compactMap { index, task in
                guard !task.deleted, !task.completed else { return nil }
                return index
            }
    }

    private func feedbackObjectIDs(from feedbacks: [ActiveFeedback]) -> Set<Int> {
        let objectIDs: [Int] = feedbacks.compactMap { feedback in
            guard let objectID = feedback.objectId else { return nil }
            return Int(objectID)
        }
        return Set(objectIDs)
    }

    private func indicesForDisplayableTasks(
        in tasks: inout [Task],
        feedbackObjectIDs: Set<Int>
    ) -> [Int] {
        tasks.enumerated().compactMap { index, task in
            guard !task.deleted else { return nil }
            
            var shouldBeShown: Bool {
                guard
                    let taskCompletedDate = task.completedAtDate,
                    let hoursPassed = Calendar.current.dateComponents(
                        [.hour],
                        from: taskCompletedDate,
                        to: Date()
                    ).hour
                else { return false }
                
                let feedbackWindowInHours = feedbackWindowInHours(for: task.taskType?.type ?? .other)
                return hoursPassed < feedbackWindowInHours
            }

            if !task.completed || (feedbackObjectIDs.contains(task.taskID) && shouldBeShown) {
                return index
            }
            return nil
        }
    }
    
    private func feedbackWindowInHours(for taskType: TaskTypeEnumeration) -> Int {
        Constants.taskTypesWithExtendedFeedbackWindow.contains(taskType) ? 48 : 24
    }

    func numberOfTasks(in list: HomeTaskManagerList) -> Int {
        switch list {
        case .all: tasks.count
        case .active: activeTasksIndices.count
        case .displayable: displayableTasksIndices.count
        }
    }

    func tasks(from list: HomeTaskManagerList, where filter: (Task) -> Bool) -> [Task] {
        switch list {
        case .all:
            tasks.filter(filter)
        case .active:
            activeTasksIndices.compactMap { index in
                let task = tasks[index]
                return filter(task) ? task : nil
            }
        case .displayable:
            displayableTasksIndices.compactMap { index in
                let task = tasks[index]
                return filter(task) ? task : nil
            }
        }
    }
}

// MARK: - HomeFeedbackManagerDelegate

extension HomeTaskManager: HomeFeedbackManagerDelegate {

    func displayableTaskWithID(_ taskID: Int) -> Task? {
        task(from: .displayable) { $0.taskID == taskID }
    }
}

// MARK: - Constants

private enum Constants {
    
    static let taskTypesWithExtendedFeedbackWindow: Set<TaskTypeEnumeration> = Set([
        .privateJet,
        .helicopter,
        .airlineLoyaltyProgramm,
        .avia,
        .lowCost,
        .hotel,
        .trip,
        .transportInfo,
        .vipLounge,
        .chaufferService,
        .carRental,
        .transfer,
        .train,
        .yachtRent,
        .visa,
        .visaDocuments,
        .travelInsurance,
        .otherInsurance,
        .tickets,
    ])
    
}
