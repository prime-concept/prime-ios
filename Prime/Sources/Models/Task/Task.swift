import ChatSDK
import Foundation

struct TasksResponse: Decodable {
    struct ViewerContainer: Decodable {
        let viewer: Viewer
    }

    struct Viewer: Decodable {
        let typename: String
        let tasks: [Task]

        enum CodingKeys: String, CodingKey {
            case typename = "__typename"
            case tasks
        }
    }

    let data: ViewerContainer
}

struct Task: Decodable, Hashable {
    private(set) var id: Int
    private(set) var taskID: Int
    private(set) var chatID: String?
    private(set) var taskType: TaskType?

    private var _customID: String?

    private(set) var title: String?
    private(set) var subtitle: String?
    private(set) var description: String?
    private(set) var reserved: Bool

    var completed: Bool
    private(set) var completedAt: Int
    private(set) var completedAtDate: Date?

    private(set) var optionID: Int?
    var orders: [Order]
    var hasAddress: Bool {
        let types: [TaskTypeEnumeration] = [.avia, .hotel, .restaurants, .carRental, .vipLounge]
        let hasAddress = types.contains(self.taskType?.type ?? .other)
        return hasAddress
    }

    private(set) var customerID: Int

    // sSD, потом смотрим date
    private(set) var date: String?
    private(set) var startServiceDate, endServiceDate: String?
    private(set) var requestDate: String?
    private(set) var taskDate: Date?
    private(set) var startServiceDateFormatted: String?
    private(set) var startServiceDateDay: Date?
    private(set) var endServiceDateDay: Date?
    private(set) var updatedAt: Date

    private(set) var latitude, longitude: Double?
    private(set) var taskCloseStateRaw: String?
    private(set) var etag: String?
    private(set) var deleted: Bool
    private(set) var address: String?
    var unreadCount: Int = 0

    var details: [TaskDetail]
    var responsible: Assistant?
    var lastChatMessage: Message?

    var latestDraft: Message?
    var taskCloseState: TaskCloseState? {
        TaskCloseState.init(rawValue: self.taskCloseStateRaw ?? "")
    }
    var events: [CalendarEvent] = [] {
        didSet {
            self.events = events.map { event in
                var newEvent = event
                newEvent.task = self
                return newEvent
            }
        }
    }

    var attachedFiles: [FilesResponse.File] = []

    var customID: String {
        self._customID ?? "\(self.id)_\(self.taskID)"
    }

    mutating func updateCustomID(_ customID: String) {
        self._customID = customID
    }

    enum CodingKeys: String, CodingKey {
        case chatID = "chatId"
        case completed
        case completedAt
        case customerID = "customerId"
        case date, description, details, startServiceDate, endServiceDate, id
        case optionID = "optionId"
        case orders, requestDate, reserved
        case taskID = "taskId"
        case taskType, title
        case latitude, longitude
        case lastChatMessage
        case taskCloseStateRaw = "taskCloseState"
        case responsible
        case etag
        case deleted
        case updatedAt
        case address
        case unreadCount
    }

    var isDecodingFailed: Bool {
        self.taskID == Self.FAILED_DECODING_ENTITY_ID
    }

    var hasCoordinates: Bool {
        self.longitude != nil && self.latitude != nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let taskID = (try? container.decode(Int.self, forKey: .taskID)) ?? Self.FAILED_DECODING_ENTITY_ID
        let responsible = try? container.decodeIfPresent(Assistant.self, forKey: .responsible)
        let details = (try? container.decodeIfPresent([TaskDetail].self, forKey: .details)) ?? []

        self.taskID = taskID
        self.details = details
        self.responsible = responsible
        self.chatID = try? container.decodeIfPresent(String.self, forKey: .chatID)
        self.completed = (try? container.decodeIfPresent(Bool.self, forKey: .completed)) ?? false
        self.customerID = (try? container.decode(Int.self, forKey: .customerID)) ?? Task.FAILED_DECODING_ENTITY_ID
        self.date = try? container.decodeIfPresent(String.self, forKey: .date)
        self.description = try? container.decodeIfPresent(String.self, forKey: .description)
        self.startServiceDate = try? container.decodeIfPresent(String.self, forKey: .startServiceDate)
        self.endServiceDate = try? container.decodeIfPresent(String.self, forKey: .endServiceDate)
        self.id = (try? container.decode(Int.self, forKey: .id)) ?? Task.FAILED_DECODING_ENTITY_ID
        self.optionID = try? container.decodeIfPresent(Int.self, forKey: .optionID)
        self.orders = (try? container.decodeIfPresent([Order].self, forKey: .orders)) ?? []
        self.requestDate = try? container.decodeIfPresent(String.self, forKey: .requestDate)
        self.reserved = (try? container.decodeIfPresent(Bool.self, forKey: .reserved)) ?? false
        self.taskType = try? container.decodeIfPresent(TaskType.self, forKey: .taskType)
        self.title = try? container.decodeIfPresent(String.self, forKey: .title)
        self.latitude = try? container.decodeIfPresent(Double.self, forKey: .latitude)
        self.longitude = try? container.decodeIfPresent(Double.self, forKey: .longitude)
        self.lastChatMessage = try? container.decodeIfPresent(Message.self, forKey: .lastChatMessage)
        self.taskCloseStateRaw = try? container.decodeIfPresent(String.self, forKey: .taskCloseStateRaw)
        self.etag = try? container.decode(String.self, forKey: .etag)
        self.deleted = (try? container.decodeIfPresent(Bool.self, forKey: .deleted)) ?? false
        self.address = try? container.decodeIfPresent(String.self, forKey: .address)
        var updatedAtDate: Date?
        (try? container.decodeIfPresent(String.self, forKey: .updatedAt)).some {
            updatedAtDate = $0.serverDate
        }
        self.updatedAt = updatedAtDate ?? Date(timeIntervalSince1970: 0)
        self.unreadCount = (try? container.decodeIfPresent(Int.self, forKey: .unreadCount)) ?? 0
        self.completedAt = (try? container.decodeIfPresent(Int.self, forKey: .completedAt)) ?? 0

        self.initComputableProperties()
    }

    init(
        chatID: String? = nil,
        completed: Bool = false,
        completedAt: Int = 0,
        completedAtDate: Date? = Date(timeIntervalSince1970: 0),
        customerID: Int,
        date: String? = nil,
        description: String? = nil,
        details: [TaskDetail] = [],
        startServiceDate: String? = nil,
        endServiceDate: String? = nil,
        id: Int,
        optionID: Int? = nil,
        orders: [Order] = [],
        events: [CalendarEvent] = [],
        requestDate: String? = nil,
        reserved: Bool = false,
        taskID: Int,
        taskType: TaskType? = nil,
        title: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        lastChatMessage: Message? = nil,
        latestDraft: Message? = nil,
        taskCloseStateRaw: String? = nil,
        responsible: Assistant? = nil,
        etag: String? = nil,
        deleted: Bool = false,
        updatedAt: Date,
        unreadCount: Int = 0,
        address: String? = nil,
        taskDate: Date? = nil,
        subtitle: String? = nil,
        startServiceDateFormatted: String? = nil,
        startServiceDateDay: Date? = nil,
        attachedFiles: [FilesResponse.File] = []
    ) {
        self.chatID = chatID
        self.completed = completed
        self.customerID = customerID
        self.date = date
        self.description = description
        self.details = details
        self.startServiceDate = startServiceDate
        self.endServiceDate = endServiceDate
        self.id = id
        self.optionID = optionID
        self.orders = orders
        self.events = events
        self.requestDate = requestDate
        self.reserved = reserved
        self.taskID = taskID
        self.taskType = taskType
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.lastChatMessage = lastChatMessage
        self.latestDraft = latestDraft
        self.taskCloseStateRaw = taskCloseStateRaw
        self.responsible = responsible
        self.etag = etag
        self.deleted = deleted
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
        self.address = address

        self.taskDate = taskDate
        self.subtitle = subtitle
        self.startServiceDateFormatted = startServiceDateFormatted
        self.startServiceDateDay = startServiceDateDay

        self.completedAt = completedAt
        self.completedAtDate = completedAtDate

        self.attachedFiles = attachedFiles
    }

    private mutating func initComputableProperties() {
        if let string = self.startServiceDate, let date = Date(string: string) {
            self.startServiceDateFormatted = date.string("dd.MM.yy")
            self.startServiceDateDay = date.down(to: .day)
        }

        if let string = self.endServiceDate, let date = Date(string: string) {
            self.endServiceDateDay = date.down(to: .day)
        }

        self.taskDate = {
            let string = self.startServiceDate ?? self.date ?? ""
            return PrimeDateFormatter.serverDate(from: string)
        }()

        func trim(_ string: String?) -> String? {
            var string = string
            string = string?.trimmingCharacters(in: .whitespacesAndNewlines)
            string = string?.replacing(regex: "\\s*\\n\\s*", with: " ")
            return string
        }

        self.title = trim(self.title)

        let subtitle = self.hasAddress ? self.address : self.description
        self.subtitle = trim(subtitle)

        if self.completedAt != 0 {
            self.completedAtDate = Date(timeIntervalSince1970: Double(self.completedAt))
        }
    }

    fileprivate static let datesCacheLock = NSLock()

    @PersistentCodable(fileName: "Task.TaskCalendarDisplayableDatesCache", async: false)
    fileprivate static var calendarDisplayableDatesCache = [String: String]()

    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.taskID == rhs.taskID
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.taskID)
    }
}

extension Task {
    var eventRelatedMonths: [Date] {
        let dates = [self.taskDate, self.startServiceDateDay, self.endServiceDateDay, self.latestChatActionDate]
        return dates.compactMap{ $0?.down(to: .month) }
    }
}

extension Task {
    var latestChatActionDate: Date? {
        [
            self.lastChatMessage?.timestamp,
            self.latestDraft?.timestamp
        ].compactMap { $0 }.max()
    }

    func isMoreRecentlyUpdated(than task: Task) -> Bool {
        let date1 = [self.latestChatActionDate.or1970, self.updatedAt].sorted(by: >)[0]
        let date2 = [task.latestChatActionDate.or1970, task.updatedAt].sorted(by: >)[0]

        return date1 ?> date2
    }

    func isMoreRecentlyUpdatedIgnoringDrafts(than task: Task) -> Bool {
        let date1 = [(self.lastChatMessage?.timestamp).or1970, self.updatedAt].sorted(by: >)[0]
        let date2 = [(task.lastChatMessage?.timestamp).or1970, task.updatedAt].sorted(by: >)[0]

        return date1 ?> date2
    }
}

extension Task {
    static let aeroticketFlightTaskID = -1000
}

struct TaskDetail: Codable {
    var code: String?
    var icon: String?
    var latitude: Double?
    var longitude: Double?
    var name: String?
    var rightText: String?
    var shareable: Bool?
    var size: String?
    var type: String?
    var value: String?
    var url: URL?

    var hasMeaningfulCoordinates: Bool {
        self.latitude != .nilCoordinate && self.longitude != .nilCoordinate
    }
}

enum TaskCloseState: String {
    case completed = "COMPLETED"
    case notCompleted = "NOT_COMPLETED"
    case cancelled = "CANCELLED"
}

extension Task {
    var ordersWaitingForPayment: [Order] {
        orders.filter(\.isWaitingForPayment)
    }

    var isWaitingForPayment: Bool {
        return !self.ordersWaitingForPayment.isEmpty
    }
}

protocol TaskCalendarDisplayable {
    var id: Int { get }

    var task: Task? { get }
    var events: [CalendarEvent] { get }

    var allDay: Bool { get }

    var isCheckin: Bool { get }
    var isCheckout: Bool { get }

    var dateStart: Date? { get }
    var dateEnd: Date? { get }

    var displayableDate: String? { get }
}

extension Task: TaskCalendarDisplayable {
    var task: Task? { self }

    var dateStart: Date? {
        if self.taskType?.type == .hotel {
            let lastDate = self.events.compactMap(\.startDateDate).sorted(by: <).first
            return lastDate ?? self.startServiceDate?.serverDate
        }

        return self.startServiceDate?.serverDate
    }

    var dateEnd: Date? {
        if self.taskType?.type == .hotel {
            let lastDate = self.events.compactMap(\.endDateDate).sorted(by: <).last
            return lastDate ?? self.endServiceDate?.serverDate
        }

        return self.endServiceDate?.serverDate
    }

    var allDay: Bool {
        self.events.first?.allDay == true
    }
}

extension TaskCalendarDisplayable {
    var isCheckin: Bool {
        false
    }

    var isCheckout: Bool {
        let taskType = self.task?.taskType?.type

        if case .hotel = taskType, self.events^.count == 2 {
            return true
        }

        return false
    }

    var displayableDate: String? {
        let isCheckinEvent = !(self is Task) && self.isCheckin
        let isCheckoutEvent = !(self is Task) && self.isCheckout

        let startDate = self.dateStart ?? self.dateEnd
        let endDate = isCheckoutEvent ? startDate : self.dateEnd

        var datesEqual = false
        if let startDate = startDate, let endDate = endDate {
            if self.task?.taskType?.type == .hotel {
                datesEqual = startDate.down(to: .day) == endDate.down(to: .day)
            } else {
                let difference = abs(startDate.timeIntervalSince1970 - endDate.timeIntervalSince1970)
                datesEqual = difference <= 60
            }
        }

        func cacheKey() -> String? {
            guard let taskId = self.task?.taskID else { return nil }
            var key = "\(type(of: self))-\(taskId)-\(self.id)-\(isCheckinEvent)-\(isCheckoutEvent)-\(self.allDay)-\(datesEqual)"
            key.append("-event-ids-\(self.events^.map(\.id))")
            key.append("-\(String(describing: startDate))")
            key.append("-\(String(describing: endDate))")
            return key
        }

        if let cacheKey = cacheKey(),
           let cachedValue = Task.calendarDisplayableDatesCache[cacheKey] {
            return cachedValue
        }

        let taskType = self.task?.taskType?.type

        let format = self.allDay ? "dd.MM.yy" : "dd.MM.yy, HH:mm"

        let startDateFormatted = startDate != nil ? startDate!.string(format) : nil
        let endDateFormatted = endDate != nil ? endDate!.string(format) : nil

        guard var startDate = startDateFormatted else {
            return nil
        }

        var result: String = startDate

        defer {
            if let cacheKey = cacheKey() {
                Task.datesCacheLock.lock()
                Task.calendarDisplayableDatesCache[cacheKey] = result
                Task.datesCacheLock.unlock()
            }
        }

        if datesEqual && self.allDay {
            startDate = startDate  + ", " + "smallCalendar.allDay".localized
        }

        switch taskType {
        case .avia, .hotel, .restaurants, .carRental, .vipLounge:
            guard let endDate = endDateFormatted else {
                result = startDate
                return result
            }

            if isCheckinEvent {
                result = startDate + " (" + "fullCalendar.checkIn".localized + ")"
                return result
            }

            if isCheckoutEvent {
                result = endDate + " (" + "fullCalendar.checkOut".localized + ")"
                return result
            }

            if datesEqual {
                result = startDate
                return result
            }

            result = startDate + " – " + endDate

        default:
            result = startDate
            return result
        }

        return result
    }
}

extension Task {
    //https://www.google.com/maps/search/54.631775+39.698124
    private static let googleMapsSearchURL = "https://www.google.com/maps/search/"
    private static let numberFormatter = with(NumberFormatter()) {
        $0.decimalSeparator = "."
        $0.maximumFractionDigits = 6
    }

    var googleMapsURL: URL? {
        guard let latitude = self.latitude, let longitude = self.longitude else {
            return nil
        }

        guard let latitudeFormatted = Self.numberFormatter.string(from: NSNumber(value: latitude)),
              let longitudeFormatted = Self.numberFormatter.string(from: NSNumber(value: longitude)) else {
            return nil
        }

        let urlString = Self.googleMapsSearchURL + "\(latitudeFormatted)+\(longitudeFormatted)"
        return URL(string: urlString)
    }
}

extension Array where Element == Task {
    var active: [Task] {
        self.existing.skip { $0.completed }
    }

    var existing: [Task] {
        self.skip { $0.deleted }
    }

    var todayAndFutureTasks: [Task] {
        let tasks = self.skip(\.completed)
        let today = Date().down(to: .day)
        let recentTasks = tasks.filter { task in
            let dates = [task.taskDate, task.dateStart, task.dateEnd]
            let latestDate = dates.compactMap{ $0 }.sorted(by: >).first

            guard let date = latestDate else {
                return false
            }
            return date >= today
        }
        return recentTasks
    }
}
