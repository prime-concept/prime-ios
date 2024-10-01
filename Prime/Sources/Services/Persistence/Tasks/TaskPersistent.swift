import Foundation
import RealmSwift

// FIXME:- add Orders after merge https://github.com/workingeeks/prime_ios/pull/7
final class TaskPersistent: Object {
    @objc dynamic var chatID: String?
    @objc dynamic var completed: Bool = false
	@objc dynamic var completedAt: Int = 0
	@objc dynamic var completedAtDate: Date?
    @objc dynamic var customerID: Int = 0
    @objc dynamic var date: String?
    @objc dynamic var deadline: String?
    @objc dynamic var deadlineInfoDelivery: String?
    @objc dynamic var taskDescription: String?
    @objc dynamic var startServiceDate: String?
    @objc dynamic var endServiceDate: String?
    @objc dynamic var id: Int = 0
    @objc dynamic var requestDate: String?
    @objc dynamic var reserved: Bool = false
    @objc dynamic var taskID: Int = 0
    @objc dynamic var taskType: TaskTypePersistent?
    @objc dynamic var title: String?
    @objc dynamic var assistant: TaskAssistantPersistent?
    @objc dynamic var lastChatMessage: TaskMessagePersistent?
	@objc dynamic var latestDraft: TaskMessagePersistent?
    @objc dynamic var etag: String?
    @objc dynamic var deleted: Bool = false
	@objc dynamic var updatedAt = Date(timeIntervalSince1970: 0)
	@objc dynamic var unreadCount: Int = 0
    @objc dynamic var address: String?
	@objc dynamic var taskDate: Date?
	@objc dynamic var subtitle: String?
	@objc dynamic var formattedDate: String?
	@objc dynamic var startServiceDateFormatted: String?
	@objc dynamic var startServiceDateDay: Date?

    var latitude = RealmOptional<Double>()
    var longitude = RealmOptional<Double>()
    var optionID = RealmOptional<Int>()

    var orders = List<OrderPersistent>()
	var details = List<TaskDetailPersistent>()
	var events = List<CalendarEventPersistent>()
	var attachedFiles = List<FilePersistent>()

    override class func primaryKey() -> String? { "taskID" }
}

extension Task: RealmObjectConvertible {
    typealias RealmObjectType = TaskPersistent

    init(realmObject: TaskPersistent) {
		let taskType: TaskType? = realmObject.taskType
			.flatMap(TaskType.init(realmObject:))

        let responsible: Assistant? = realmObject.assistant
			.flatMap(Assistant.init(realmObject:))

        let lastMessage = realmObject.lastChatMessage
			.flatMap(Message.init(realmObject:))

		let latestDraft = realmObject.latestDraft
			.flatMap(Message.init(realmObject:))
		
        self = Task(
            chatID: realmObject.chatID,
            completed: realmObject.completed,
			completedAt: realmObject.completedAt,
			completedAtDate: realmObject.completedAtDate,
            customerID: realmObject.customerID,
            date: realmObject.date ?? "",
            description: realmObject.taskDescription,
			details: realmObject.details.map(TaskDetail.init(realmObject:)),
            startServiceDate: realmObject.startServiceDate ?? "",
            endServiceDate: realmObject.endServiceDate ?? "",
            id: realmObject.id,
            optionID: realmObject.optionID.value,
			orders: realmObject.orders.map(Order.init(realmObject:)),
			events: realmObject.events.map(CalendarEvent.init(realmObject:)),
            requestDate: realmObject.requestDate ?? "",
            reserved: realmObject.reserved,
            taskID: realmObject.taskID,
            taskType: taskType,
            title: realmObject.title,
            latitude: realmObject.latitude.value,
            longitude: realmObject.longitude.value,
            lastChatMessage: lastMessage,
			latestDraft: latestDraft,
            taskCloseStateRaw: nil,
            responsible: responsible,
            etag: realmObject.etag,
            deleted: realmObject.deleted,
			updatedAt: realmObject.updatedAt,
			unreadCount: realmObject.unreadCount,
            address: realmObject.address,
			taskDate: realmObject.taskDate,
			subtitle: realmObject.subtitle,
			startServiceDateFormatted: realmObject.startServiceDateFormatted,
			startServiceDateDay: realmObject.startServiceDateDay,
			attachedFiles: realmObject.attachedFiles.map(FilesResponse.File.init(realmObject:))
        )
    }

    var realmObject: TaskPersistent { TaskPersistent(plainObject: self) }
}

extension TaskPersistent {
    convenience init(plainObject: Task) {
        self.init()
        self.chatID = plainObject.chatID
        self.completed = plainObject.completed
		self.completedAt = plainObject.completedAt
		self.completedAtDate = plainObject.completedAtDate
		self.customerID = plainObject.customerID
        self.date = plainObject.date
        self.taskDescription = plainObject.description
		self.details.append(objectsIn: plainObject.details.map { $0.realmObject })
        self.startServiceDate = plainObject.startServiceDate
        self.endServiceDate = plainObject.endServiceDate
        self.id = plainObject.id
        self.optionID = RealmOptional<Int>(plainObject.optionID)
        self.orders.append(objectsIn: plainObject.orders.map { $0.realmObject })
		self.events.append(objectsIn: plainObject.events^.map { $0.realmObject })
        self.requestDate = plainObject.requestDate
        self.reserved = plainObject.reserved
        self.taskID = plainObject.taskID
        self.taskType = plainObject.taskType?.realmObject
        self.title = plainObject.title
        self.latitude = RealmOptional<Double>(plainObject.latitude)
        self.longitude = RealmOptional<Double>(plainObject.longitude)
        self.lastChatMessage = plainObject.lastChatMessage?.realmObject
		self.latestDraft = plainObject.latestDraft?.realmObject
        self.assistant = plainObject.responsible?.realmObject
        self.deleted = plainObject.deleted
        self.etag = plainObject.etag
		self.updatedAt = plainObject.updatedAt
		self.unreadCount = plainObject.unreadCount
        self.address = plainObject.address
		self.taskDate = plainObject.taskDate
		self.subtitle = plainObject.subtitle
		self.startServiceDateFormatted = plainObject.startServiceDateFormatted
		self.startServiceDateDay = plainObject.startServiceDateDay
    }
}
