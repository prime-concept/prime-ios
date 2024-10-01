import UIKit
import ChatSDK

struct CompletedTaskViewModel {
    let task: Task
    let title: String?
    let subtitle: String?
    let date: String?
    let image: UIImage?
    let taskType: TaskType?
    let order: TasksListPayItemViewModel?
    let type: TasksListType

    init(
        task: Task,
        type: TasksListType = .waitingForPayment,
        order: Order? = nil,
        onTapOrder: @escaping (URL?) -> Void = { _ in return }
    ) {
        self.task = task
        self.title = task.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.subtitle = task.subtitle
        self.date = task.displayableDate
        self.image = task.taskType?.image
        self.taskType = task.taskType
        self.type = type
        self.order = order != nil ? TasksListPayItemViewModel(order: order!, onTapOrder: onTapOrder) : nil
    }
}
