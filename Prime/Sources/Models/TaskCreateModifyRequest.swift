import Foundation

class TaskCreateModifyRequest: Encodable {
    let cityId: Int = 76
    let deadline = Date().addingTimeInterval(60 * 60 * 24).customDateTimeString
    let deadlineInfoDelivery = Date().addingTimeInterval(60 * 60 * 24).customDateTimeString
    let source = "APPLICATION"
    let taskDirector = "CUSTOMER"
    let taskTypeId: Int
    let fieldValues: [TaskFieldValueInput]
    let marginId: Int = 0

    init(taskTypeId: Int, fieldValues: [TaskFieldValueInput]) {
        self.taskTypeId = taskTypeId
        self.fieldValues = fieldValues
    }
}

class SaveTaskResponse: Decodable {
    struct Data: Decodable {
        let customer: Customer
    }

    struct Customer: Decodable {
        let task: Task
    }

    struct Task: Decodable {
        let saveTask: SaveTask
    }

    struct SaveTask: Decodable {
        let httpCode: Int?
        let taskId: Int?
        let errors: String?
    }

    let data: Data

    var taskId: Int? {
        self.data.customer.task.saveTask.taskId
    }
}

enum SaveTaskError: Error {
    case unknownError
}
