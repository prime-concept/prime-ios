@testable import Prime

import XCTest

final class HomeFeedbackManagerTests: XCTestCase {
    
    private var manager: HomeFeedbackManager!
    private var delegate: HomeFeedbackManagerDelegateMock!
    
    override func setUpWithError() throws {
        manager = HomeFeedbackManager()
        delegate = HomeFeedbackManagerDelegateMock()
        manager.delegate = delegate
    }
    
    func test_replaceAllFeedbacks_emptySource_emptyDestination() {
        manager.replaceAllFeedbacks(with: [])
        
        XCTAssertTrue(manager.activeFeedbacks.isEmpty)
    }
    
    func test_replaceAllFeedbacks_nonEmptySource_emptyDestination() {
        let feedbacks = [HomeTestUtilities.feedback(), HomeTestUtilities.feedback()]
        
        manager.replaceAllFeedbacks(with: feedbacks)
        
        XCTAssertEqual(manager.activeFeedbacks.count, 2)
    }
    
    func test_replaceAllFeedbacks_emptySource_nonEmptyDestination() {
        manager.activeFeedbacks = [HomeTestUtilities.feedback()]
        
        manager.replaceAllFeedbacks(with: [])
        
        XCTAssertTrue(manager.activeFeedbacks.isEmpty)
    }
    
    func test_replaceAllFeedbacks_nonEmptySource_nonEmptyDestination() {
        manager.activeFeedbacks = [HomeTestUtilities.feedback(), HomeTestUtilities.feedback()]
        
        let feedbacks = [HomeTestUtilities.feedback()]
        
        manager.replaceAllFeedbacks(with: feedbacks)
        
        XCTAssertEqual(manager.activeFeedbacks.count, 1)
    }
    
    func test_feedbackForTask_match() {
        manager.activeFeedbacks = [HomeTestUtilities.feedback(objectID: 123)]
        let task = HomeTestUtilities.task(id: 123, completionDate: Date(timeIntervalSinceNow: -12 * 60 * 60))
        
        let feedback = manager.feedbackForTask(task)
        
        XCTAssertNotNil(feedback)
        XCTAssertEqual(feedback?.objectId, String(task.taskID))
        XCTAssertEqual(feedback?.taskType?.id, task.taskType?.id)
        XCTAssertEqual(feedback?.taskTitle, task.title)
        XCTAssertEqual(feedback?.taskSubtitle, task.description)
    }
    
    func test_feedbackForTask_noMatch() {
        manager.activeFeedbacks = [HomeTestUtilities.feedback(objectID: 123)]
        let task = HomeTestUtilities.task(id: 456, completionDate: Date(timeIntervalSinceNow: -12 * 60 * 60))
        
        let feedback = manager.feedbackForTask(task)
        
        XCTAssertNil(feedback)
    }
    
    func test_feedbackWithGUID_feedbackMatch_taskMatch() {
        let guid = "TEST_GUID_123"
        let taskID = 456
        manager.activeFeedbacks = [HomeTestUtilities.feedback(guid: guid, objectID: taskID)]
        let task = HomeTestUtilities.task(id: taskID, completionDate: Date(timeIntervalSinceNow: -12 * 60 * 60))
        delegate.displayableTaskWithID_returnValue = task
        
        let feedback = manager.feedbackWithGUID(guid)
        
        XCTAssertEqual(delegate.displayableTaskWithID_invocationCount, 1)
        XCTAssertNotNil(feedback)
        XCTAssertEqual(feedback?.guid, guid)
        XCTAssertEqual(feedback?.objectId, String(task.taskID))
        XCTAssertEqual(feedback?.taskType?.id, task.taskType?.id)
        XCTAssertEqual(feedback?.taskTitle, task.title)
        XCTAssertEqual(feedback?.taskSubtitle, task.description)
        
    }
    
    func test_feedbackWithGUID_feedbackMatch_noTaskMatch() {
        let guid = "TEST_GUID_123"
        manager.activeFeedbacks = [HomeTestUtilities.feedback(guid: guid, objectID: 123)]
        let task = HomeTestUtilities.task(id: 456, completionDate: Date(timeIntervalSinceNow: -12 * 60 * 60))
        delegate.displayableTaskWithID_returnValue = task
        
        let feedback = manager.feedbackWithGUID(guid)
        
        XCTAssertEqual(delegate.displayableTaskWithID_invocationCount, 1)
        XCTAssertNil(feedback)
    }
    
    func test_feedbackWithGUID_noFeedbackMatch_noTaskMatch() {
        manager.activeFeedbacks = [HomeTestUtilities.feedback(guid: "TEST_GUID_123")]
        
        let feedback = manager.feedbackWithGUID("TEST_GUID_456")
        
        XCTAssertEqual(delegate.displayableTaskWithID_invocationCount, 0)
        XCTAssertNil(feedback)
    }
}
