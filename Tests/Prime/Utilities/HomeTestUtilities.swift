@testable import Prime

enum HomeTestUtilities {
    
    static func feedback(
        guid: String? = "TEST_\(Int.random(in: 1...1_000))",
        objectID: Int? = nil
    ) -> ActiveFeedback {
        ActiveFeedback(
            guid: guid,
            objectId: objectID?.description,
            sourceId: nil,
            ratingSource: nil,
            ratingType: nil,
            ratingValueSelectList: [],
            createdAt: nil,
            showOnTask: false
        )
    }
    
    static func task(
        id: Int = Int.random(in: 1...1_000),
        completionDate: Date? = nil,
        customizationHandler: (Task) -> Task = { $0 }
    ) -> Task {
        let task = Task(
            completed: completionDate != nil,
            completedAt: 0,
            completedAtDate: completionDate,
            customerID: 0,
            id: 0,
            orders: [],
            reserved: false,
            taskID: id,
            deleted: false,
            updatedAt: Date.distantPast,
            unreadCount: 0,
            taskDate: nil,
            subtitle: "TEST Subtitle",
            startServiceDateFormatted: nil,
            startServiceDateDay: nil,
            attachedFiles: []
        )
        return customizationHandler(task)
    }
}
