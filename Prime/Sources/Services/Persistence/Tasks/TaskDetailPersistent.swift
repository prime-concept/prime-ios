import Foundation
import RealmSwift

final class TaskDetailPersistent: Object {
	@objc dynamic var id: String = ""
	@objc dynamic var code: String? = ""
	@objc dynamic var icon: String? = ""
	@objc dynamic var latitude: Double = .nilCoordinate
	@objc dynamic var longitude: Double = .nilCoordinate
	@objc dynamic var name: String? = ""
	@objc dynamic var rightText: String? = ""
	@objc dynamic var shareable: Bool = false
	@objc dynamic var size: String? = ""
	@objc dynamic var type: String? = ""
	@objc dynamic var value: String? = ""

	var items = List<TaskDetailPersistent>()

	override class func primaryKey() -> String? { "id" }
}

extension TaskDetail: RealmObjectConvertible {
	typealias RealmObjectType = TaskDetailPersistent

	init(realmObject: TaskDetailPersistent) {
		self.code = realmObject.code
		self.icon = realmObject.icon
		self.latitude = realmObject.latitude
		self.longitude = realmObject.longitude
		self.name = realmObject.name
		self.rightText = realmObject.rightText
		self.shareable = realmObject.shareable
		self.size = realmObject.size
		self.type = realmObject.type
		self.value = realmObject.value
	}

	var realmObject: TaskDetailPersistent { TaskDetailPersistent(plainObject: self) }
}

extension TaskDetailPersistent {
	convenience init(plainObject: TaskDetail) {
		self.init()

		self.id = UUID().uuidString
		self.code = plainObject.code
		self.icon = plainObject.icon
		self.latitude = plainObject.latitude ?? 0
		self.longitude = plainObject.longitude ?? 0
		self.name = plainObject.name
		self.rightText = plainObject.rightText
		self.shareable = plainObject.shareable ?? false
		self.size = plainObject.size
		self.type = plainObject.type
		self.value = plainObject.value
	}
}
