@testable import Prime

// MARK: - Mock

final class HomeFeedbackManagerDelegateMock {
    var displayableTaskWithID_invocationCount = 0
    var displayableTaskWithID_returnValue: Task?
}

// MARK: - HomeFeedbackManagerDelegate

extension HomeFeedbackManagerDelegateMock: HomeFeedbackManagerDelegate {
    
    func displayableTaskWithID(_ taskID: Int) -> Task? {
        displayableTaskWithID_invocationCount += 1
        return displayableTaskWithID_returnValue
    }
}

