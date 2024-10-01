import Foundation
import UIKit

struct CalendarEventsResponse: Codable {
	struct ViewerContainer: Codable {
		let viewer: Viewer
	}
	
	struct Viewer: Codable {
		let typename: String
		let events: [CalendarEvent]
		
		enum CodingKeys: String, CodingKey {
			case typename = "__typename"
			case events
		}
	}
	
	let data: ViewerContainer
}

struct CalendarEvent: Codable {
	init(
		allDay: Bool,
		backgroundImageUrl: String? = nil,
		customerId: Int,
		customerName: String? = nil,
		description: String? = nil,
		endDate: String? = nil,
		endDateDate: Date? = nil,
		id: Int,
		latitude: Double? = nil,
		location: String,
		longitude: Double? = nil,
		startDate: String? = nil,
		startDateDay: Date? = nil,
		startDateDate: Date? = nil,
		taskId: Int,
		taskInfoId: Int,
		taskTypeId: Int,
		title: String? = nil,
		url: String? = nil,
		hasReservation: Bool = false
	) {
		self.allDay = allDay
		self.backgroundImageUrl = backgroundImageUrl
		self.customerId = customerId
		self.customerName = customerName
		self.description = description
		self.endDate = endDate
		self.endDateDate = endDateDate
		self.id = id
		self.latitude = latitude
		self.location = location
		self.longitude = longitude
		self.startDate = startDate
		self.taskId = taskId
		self.taskInfoId = taskInfoId
		self.taskTypeId = taskTypeId
		self.title = title
		self.url = url
		self.hasReservation = hasReservation
		self.startDateDay = startDateDay
		self.startDateDate = startDateDate
	}

	private(set) var id: Int
	var title: String?
	private(set) var description: String?

	private(set) var allDay: Bool

	private(set) var startDate: String?
	private(set) var startDateDay: Date?
	private(set) var startDateDate: Date?

	private(set) var endDate: String?
	private(set) var endDateDate: Date?

	private(set) var backgroundImageUrl: String?
	private(set) var customerId: Int
	private(set) var customerName: String?

	private(set) var location: String?
	private(set) var latitude: Double?
	private(set) var longitude: Double?

	private(set) var taskId: Int
	private(set) var taskInfoId: Int
	private(set) var taskTypeId: Int

	private(set) var url: String?

	var hasReservation: Bool = false

	var userInfo: [String: Codable]? = nil

	var task: Task?

	enum CodingKeys: String, CodingKey {
		case allDay
		case backgroundImageUrl
		case customerId
		case customerName
		case description
		case endDate
		case id
		case latitude
		case location
		case longitude
		case startDate
		case taskId
		case taskInfoId
		case taskTypeId
		case title = "name"
		case url
	}
	
	var isDecodingFailed: Bool {
		self.taskId == Self.FAILED_DECODING_ENTITY_ID
	}
	
	var taskTypeImage: UIImage? {
		TaskType.image(for: self.taskTypeId)
	}

	private static let startDateDayMask = "yyyy-MM-dd"
	
	init(from decoder: Decoder) throws {
		do {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.allDay = try container.decodeIfPresent(Bool.self, forKey: .allDay) ?? false
			self.backgroundImageUrl = try? container.decodeIfPresent(String.self, forKey: .backgroundImageUrl)
			self.customerId = try container.decodeIfPresent(Int.self, forKey: .customerId)!
			self.customerName = try container.decodeIfPresent(String.self, forKey: .customerName)
			self.description = try container.decodeIfPresent(String.self, forKey: .description)
			self.endDate = try? container.decodeIfPresent(String.self, forKey: .endDate)
			self.id = try container.decodeIfPresent(Int.self, forKey: .id)!
			self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
			self.location = try container.decodeIfPresent(String.self, forKey: .location)
			self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
			self.startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
			self.taskId = (try? container.decodeIfPresent(Int.self, forKey: .taskId)) ?? Self.FAILED_DECODING_ENTITY_ID
			self.taskInfoId = (try? container.decodeIfPresent(Int.self, forKey: .taskInfoId)) ?? Self.FAILED_DECODING_ENTITY_ID
			self.taskTypeId = (try? container.decodeIfPresent(Int.self, forKey: .taskTypeId)) ?? Self.FAILED_DECODING_ENTITY_ID
			self.title = try container.decodeIfPresent(String.self, forKey: .title)
			self.url = try container.decodeIfPresent(String.self, forKey: .url)

			let dates = [self.startDate?.serverDate, self.endDate?.serverDate].compactMap{ $0 }.sorted(by: <)
			self.startDateDate = dates[safe: 0]
			self.endDateDate = dates[safe: 1]

			self.startDateDay = self.startDateDate?.down(to: .day)
		} catch {
			self = CalendarEvent(
				allDay: false,
				customerId: 0,
				id: 0,
				location: "",
				taskId: Self.FAILED_DECODING_ENTITY_ID,
				taskInfoId: 0,
				taskTypeId: 0
			)
		}
	}
}

extension CalendarEvent: TaskCalendarDisplayable {
	var dateStart: Date? { self.startDate?.serverDate }
	var dateEnd: Date? { self.endDate?.serverDate }
	var events: [CalendarEvent] { self.task?.events ?? [self] }

	var isCheckin: Bool {
		guard self.task?.taskType?.type == .hotel else {
			return false
		}

		let hour = self.startDateDate?[.hour]
		return hour == 14
	}

	var isCheckout: Bool {
		guard self.task?.taskType?.type == .hotel else {
			return false
		}

		let hour = self.startDateDate?[.hour]
		return hour == 11
	}
}
