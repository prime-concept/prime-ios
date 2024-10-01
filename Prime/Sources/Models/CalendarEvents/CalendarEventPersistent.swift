import Foundation
import RealmSwift

final class CalendarEventPersistent: Object {
	@objc dynamic var allDay: Bool = false
	@objc dynamic var backgroundImageUrl: String?
	@objc dynamic var customerId: Int = -1
	@objc dynamic var customerName: String?
	@objc dynamic var _description: String?
	@objc dynamic var endDate: String?
	@objc dynamic var endDateDate: Date?
	@objc dynamic var id: Int = -1
	@objc dynamic var latitude: Double = Double.greatestFiniteMagnitude
	@objc dynamic var location: String = ""
	@objc dynamic var longitude: Double = Double.greatestFiniteMagnitude
	@objc dynamic var startDate: String?
	@objc dynamic var taskId: Int = -1
	@objc dynamic var taskInfoId: Int = -1
	@objc dynamic var taskTypeId: Int = -1
	@objc dynamic var title: String?
	@objc dynamic var url: String?
	@objc dynamic var hasReservation: Bool = false
	@objc dynamic var startDateDay: Date?
	@objc dynamic var startDateDate: Date?
	@objc dynamic var formattedDate: String?

	override class func primaryKey() -> String? { "id" }
}

extension CalendarEvent: RealmObjectConvertible {
	typealias RealmObjectType = CalendarEventPersistent

	init(realmObject: CalendarEventPersistent) {
		self = CalendarEvent.init(
			allDay: realmObject.allDay,
			backgroundImageUrl: realmObject.backgroundImageUrl,
			customerId: realmObject.customerId,
			customerName: realmObject.customerName,
			description: realmObject._description,
			endDate: realmObject.endDate,
			endDateDate: realmObject.endDateDate,
			id: realmObject.id,
			latitude: realmObject.latitude,
			location: realmObject.location,
			longitude: realmObject.longitude,
			startDate: realmObject.startDate,
			startDateDay: realmObject.startDateDay,
			startDateDate: realmObject.startDateDate,
			taskId: realmObject.taskId,
			taskInfoId: realmObject.taskInfoId,
			taskTypeId: realmObject.taskTypeId,
			title: realmObject.title,
			url: realmObject.url
		)
	}

	var realmObject: CalendarEventPersistent { CalendarEventPersistent(plainObject: self) }
}

extension CalendarEventPersistent {
	convenience init(plainObject: CalendarEvent) {
		self.init()
		self.allDay = plainObject.allDay
		self.backgroundImageUrl = plainObject.backgroundImageUrl
		self.customerId = plainObject.customerId
		self.customerName = plainObject.customerName
		self._description = plainObject.description
		self.endDate = plainObject.endDate
		self.endDateDate = plainObject.endDateDate
		self.id = plainObject.id
		self.latitude = plainObject.latitude ?? Double.greatestFiniteMagnitude
		self.location = plainObject.location^
		self.longitude = plainObject.longitude ?? Double.greatestFiniteMagnitude
		self.startDate = plainObject.startDate
		self.startDateDay = plainObject.startDateDay
		self.startDateDate = plainObject.startDateDate
		self.taskId = plainObject.taskId
		self.taskInfoId = plainObject.taskInfoId
		self.taskTypeId = plainObject.taskTypeId
		self.title = plainObject.title
		self.url = plainObject.url
		self.hasReservation = plainObject.hasReservation
	}
}
