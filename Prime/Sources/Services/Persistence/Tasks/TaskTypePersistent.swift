import Foundation
import RealmSwift

final class TaskTypePersistent: Object {
    @objc dynamic var deleted: Bool = false
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
	@objc dynamic var groupId: Int = -1
	@objc dynamic var rowNumber: Int = -1

    override class func primaryKey() -> String? { "id" }
}

extension TaskType: RealmObjectConvertible {
    typealias RealmObjectType = TaskTypePersistent

    init(realmObject: TaskTypePersistent) {
        self.id = realmObject.id
        self.name = realmObject.name
		self.groupId = realmObject.groupId
		self.rowNumber = realmObject.rowNumber
		self.deleted = realmObject.deleted
    }

    var realmObject: TaskTypePersistent { TaskTypePersistent(plainObject: self) }
}

extension TaskTypePersistent {
    convenience init(plainObject: TaskType) {
        self.init()

        self.deleted = plainObject.deleted == true
        self.id = plainObject.id
        self.name = plainObject.name
		self.groupId = plainObject.groupId ?? -1
		self.rowNumber = plainObject.rowNumber ?? -1
    }
}
