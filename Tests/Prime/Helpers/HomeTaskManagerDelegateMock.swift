@testable import Prime

final class HomeTaskManagerDelegateMock {
    var taskManagerHasDisplayableTasks_invocationCount = 0
}

extension HomeTaskManagerDelegateMock: HomeTaskManagerDelegate {
    
    func taskManagerHasDisplayableTasks(_ manager: HomeTaskManager) {
        taskManagerHasDisplayableTasks_invocationCount += 1
    }
}

