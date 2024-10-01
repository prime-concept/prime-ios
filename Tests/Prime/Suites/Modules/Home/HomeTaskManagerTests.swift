@testable import Prime

import XCTest

final class HomeTaskManagerTests: XCTestCase {
    
    private var manager: HomeTaskManager!
    private var delegate: HomeTaskManagerDelegateMock!
    
    override func setUpWithError() throws {
        delegate = HomeTaskManagerDelegateMock()
        manager = HomeTaskManager()
        manager.delegate = delegate
    }
    
    func test_replaceAllTasks_emptySource_emptyDestination() {
        manager.replaceAllTasks(with: [], feedbacks: [])
        
        XCTAssertTrue(manager.tasks.isEmpty)
        XCTAssertTrue(manager.activeTasksIndices.isEmpty)
        XCTAssertTrue(manager.displayableTasksIndices.isEmpty)
    }
    
    func test_replaceAllTasks_emptySource_nonEmptyDestination() {
        manager.tasks = [HomeTestUtilities.task()]
        manager.activeTasksIndices = [0]
        manager.displayableTasksIndices = [0]
        
        manager.replaceAllTasks(with: [], feedbacks: [])
        
        XCTAssertTrue(manager.tasks.isEmpty)
        XCTAssertTrue(manager.activeTasksIndices.isEmpty)
        XCTAssertTrue(manager.displayableTasksIndices.isEmpty)
    }
    
    func test_replaceAllTasks_nonEmptySource_emptyDestination() {
        let task1 = HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -12 * 60 * 60))
        let task2 = HomeTestUtilities.task()
        let newTasks = [task1, task2]
        let feedbacks = [HomeTestUtilities.feedback(objectID: task1.taskID)]
        
        manager.replaceAllTasks(with: newTasks, feedbacks: feedbacks)
        
        XCTAssertEqual(manager.tasks, newTasks)
        XCTAssertEqual(manager.activeTasksIndices, [1])
        XCTAssertEqual(manager.displayableTasksIndices, [0, 1])
        XCTAssertEqual(delegate.taskManagerHasDisplayableTasks_invocationCount, 1)
    }
    
    func test_replaceAllTasks_nonEmptySource_nonEmptyDestination() {
        manager.tasks = [HomeTestUtilities.task()]
        manager.activeTasksIndices = [0]
        manager.displayableTasksIndices = [0]
        
        let task1 = HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -12 * 60 * 60))
        let task2 = HomeTestUtilities.task()
        let newTasks = [task1, task2]
        let feedbacks = [HomeTestUtilities.feedback(objectID: task1.taskID)]
        
        manager.replaceAllTasks(with: newTasks, feedbacks: feedbacks)
        
        XCTAssertEqual(manager.tasks, newTasks)
        XCTAssertEqual(manager.activeTasksIndices, [1])
        XCTAssertEqual(manager.displayableTasksIndices, [0, 1])
        XCTAssertEqual(delegate.taskManagerHasDisplayableTasks_invocationCount, 1)
    }
    
    func test_numberOfTasks_all_tasks() {
        manager.tasks = [HomeTestUtilities.task(), HomeTestUtilities.task(), HomeTestUtilities.task()]
        
        XCTAssertEqual(manager.numberOfTasks(in: .all), 3)
    }
    
    func test_numberOfTasks_all_noTasks() {
        XCTAssertEqual(manager.numberOfTasks(in: .all), 0)
    }
    
    func test_numberOfTasks_active_tasks() {
        manager.tasks = [HomeTestUtilities.task(), HomeTestUtilities.task(), HomeTestUtilities.task()]
        manager.activeTasksIndices = [2]
        
        XCTAssertEqual(manager.numberOfTasks(in: .active), 1)
    }
    
    func test_numberOfTasks_active_noTasks() {
        manager.tasks = [HomeTestUtilities.task(), HomeTestUtilities.task(), HomeTestUtilities.task()]
        
        XCTAssertEqual(manager.numberOfTasks(in: .active), 0)
    }
    
    func test_numberOfTasks_displayable_tasks() {
        manager.tasks = [HomeTestUtilities.task(), HomeTestUtilities.task(), HomeTestUtilities.task()]
        manager.displayableTasksIndices = [0, 2]
        
        XCTAssertEqual(manager.numberOfTasks(in: .displayable), 2)
    }
    
    func test_numberOfTasks_displayable_noTasks() {
        manager.tasks = [HomeTestUtilities.task(), HomeTestUtilities.task(), HomeTestUtilities.task()]
        
        XCTAssertEqual(manager.numberOfTasks(in: .displayable), 0)
    }
    
    func test_tasks_all_passthroughFilter_tasks() {
        manager.tasks = [HomeTestUtilities.task(), HomeTestUtilities.task(), HomeTestUtilities.task()]
        
        let tasks = manager.tasks(from: .all) { _ in true }
        
        XCTAssertEqual(tasks.count, 3)
    }
    
    func test_tasks_all_passthroughFilter_noTasks() {
        let tasks = manager.tasks(from: .all) { _ in true }
        
        XCTAssertTrue(tasks.isEmpty)
    }
    
    func test_tasks_all_filter_tasks() {
        manager.tasks = [HomeTestUtilities.task(id: 5), HomeTestUtilities.task(id: 10), HomeTestUtilities.task(id: 15)]
        
        let tasks = manager.tasks(from: .all) { task in
            task.taskID.isMultiple(of: 2)
        }
        
        XCTAssertEqual(tasks.count, 1)
    }
    
    func test_tasks_all_filter_noTasks() {
        manager.tasks = [HomeTestUtilities.task(id: 5), HomeTestUtilities.task(id: 10), HomeTestUtilities.task(id: 15)]
        
        let tasks = manager.tasks(from: .all) { task in
            task.taskID > 100
        }
        
        XCTAssertTrue(tasks.isEmpty)
    }
    
    func test_tasks_active_passthroughFilter_tasks() {
        manager.tasks = [
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(),
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
        ]
        manager.activeTasksIndices = [1]
        
        let tasks = manager.tasks(from: .active) { _ in true }
        
        XCTAssertEqual(tasks.count, 1)
    }
    
    func test_tasks_active_passthroughFilter_noTasks() {
        manager.tasks = [
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
        ]
        
        let tasks = manager.tasks(from: .active) { _ in true }
        
        XCTAssertTrue(tasks.isEmpty)
    }
    
    func test_tasks_active_filter_tasks() {
        manager.tasks = [
            HomeTestUtilities.task(id: 5, completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(id: 10),
            HomeTestUtilities.task(id: 15),
        ]
        manager.activeTasksIndices = [1, 2]
        
        let tasks = manager.tasks(from: .active) { task in
            task.taskID <= 10
        }
        
        XCTAssertEqual(tasks.count, 1)
    }
    
    func test_tasks_active_filter_noTasks() {
        manager.tasks = [
            HomeTestUtilities.task(id: 5),
            HomeTestUtilities.task(id: 10, completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(id: 15),
        ]
        manager.activeTasksIndices = [0, 2]
        
        let tasks = manager.tasks(from: .active) { task in
            task.taskID.isMultiple(of: 2)
        }
        
        XCTAssertTrue(tasks.isEmpty)
    }
    
    func test_tasks_displayable_passthroughFilter_tasks() {
        manager.tasks = [
            HomeTestUtilities.task(),
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
        ]
        manager.displayableTasksIndices = [0, 2]
        
        let tasks = manager.tasks(from: .displayable) { _ in true }
        
        XCTAssertEqual(tasks.count, 2)
    }
    
    func test_tasks_displayable_passthroughFilter_noTasks() {
        manager.tasks = [
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(completionDate: Date(timeIntervalSinceNow: -300)),
        ]
        manager.displayableTasksIndices = []
        
        let tasks = manager.tasks(from: .displayable) { _ in true }
        
        XCTAssertTrue(tasks.isEmpty)
    }
    
    func test_tasks_displayable_filter_tasks() {
        manager.tasks = [
            HomeTestUtilities.task(id: 5),
            HomeTestUtilities.task(id: 10, completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(id: 15, completionDate: Date(timeIntervalSinceNow: -300)),
        ]
        manager.displayableTasksIndices = [0, 2]
        
        let tasks = manager.tasks(from: .displayable) { task in
            task.taskID >= 10
        }
        
        XCTAssertEqual(tasks.count, 1)
    }
    
    func test_tasks_displayable_filter_noTasks() {
        manager.tasks = [
            HomeTestUtilities.task(id: 5),
            HomeTestUtilities.task(id: 10, completionDate: Date(timeIntervalSinceNow: -300)),
            HomeTestUtilities.task(id: 15, completionDate: Date(timeIntervalSinceNow: -300)),
        ]
        manager.displayableTasksIndices = [0, 2]
        
        let tasks = manager.tasks(from: .displayable) { task in
            task.taskID.isMultiple(of: 2)
        }
        
        XCTAssertTrue(tasks.isEmpty)
    }
    
    func test_displayableTaskWithID_match() {
        let taskID = 456
        manager.tasks = [
            HomeTestUtilities.task(id: 123),
            HomeTestUtilities.task(id: taskID),
            HomeTestUtilities.task(id: 789),
        ]
        manager.displayableTasksIndices = [0, 1, 2]
        
        let task = manager.displayableTaskWithID(taskID)
        
        XCTAssertNotNil(task)
        XCTAssertEqual(task?.taskID, taskID)
    }
    
    func test_displayableTaskWithID_noMatch() {
        let taskID = 456
        manager.tasks = [
            HomeTestUtilities.task(id: 123),
            HomeTestUtilities.task(id: taskID),
            HomeTestUtilities.task(id: 789),
        ]
        manager.displayableTasksIndices = [2]
        
        let task = manager.displayableTaskWithID(taskID)
        
        XCTAssertNil(task)
    }
}
