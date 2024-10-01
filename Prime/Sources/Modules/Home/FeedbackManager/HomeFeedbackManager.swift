// MARK: - Manager

final class HomeFeedbackManager {

    @PersistentCodable(fileName: "Home-Feedbacks")
    var activeFeedbacks = [ActiveFeedback]()

    weak var delegate: (any HomeFeedbackManagerDelegate)?
}

// MARK: - HomeFeedbackManagerProtocol

extension HomeFeedbackManager: HomeFeedbackManagerProtocol {

    var _rawFeedbacks: [ActiveFeedback] { activeFeedbacks }

    func replaceAllFeedbacks(with feedbacks: [ActiveFeedback]) {
        activeFeedbacks = feedbacks
    }

    func feedbackForTask(_ task: Task) -> ActiveFeedback? {
        guard var feedback = activeFeedbacks.first(where: { $0.objectId == String(task.taskID) }) else { return nil }

        feedback.taskType = task.taskType
        feedback.taskTitle = task.title
        feedback.taskSubtitle = task.description

        return feedback
    }

    func feedbackWithGUID(_ guid: String) -> ActiveFeedback? {
        guard
            var feedback = activeFeedbacks.first(where: { $0.guid == guid }),
            let task = taskMatchingFeedback(feedback),
            feedback.objectId == String(task.taskID)
        else { return nil }

        feedback.taskType = task.taskType
        feedback.taskTitle = task.title
        feedback.taskSubtitle = task.description

        return feedback
    }

    func feedbackWithTaskID(_ taskID: String) -> ActiveFeedback? {
        guard
            var feedback = activeFeedbacks.first(where: { $0.objectId == taskID }),
            let task = taskMatchingFeedback(feedback),
            feedback.objectId == String(task.taskID)
        else { return nil }

        feedback.taskType = task.taskType
        feedback.taskTitle = task.title
        feedback.taskSubtitle = task.description

        return feedback
    }

    private func taskMatchingFeedback(_ feedback: ActiveFeedback) -> Task? {
        guard let objectID = feedback.objectId, let taskID = Int(objectID) else { return nil }
        return delegate?.displayableTaskWithID(taskID)
    }
}
