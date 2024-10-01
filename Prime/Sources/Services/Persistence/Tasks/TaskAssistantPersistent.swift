import Foundation
import RealmSwift

final class TaskAssistantPersistent: Object {
    @objc dynamic var lastName: String = ""
    @objc dynamic var firstName: String = ""
    @objc dynamic var phone: String?
    @objc dynamic var id = UUID().uuidString

    override class func primaryKey() -> String? { "id" }
}

extension Assistant: RealmObjectConvertible {
    typealias RealmObjectType = TaskAssistantPersistent

    init(realmObject: TaskAssistantPersistent) {
        self.lastName = realmObject.lastName
        self.firstName = realmObject.firstName
        self.phone = realmObject.phone
    }

    var realmObject: TaskAssistantPersistent { TaskAssistantPersistent(plainObject: self) }
}

extension TaskAssistantPersistent {
    convenience init(plainObject: Assistant) {
        self.init()

        self.lastName = plainObject.lastName
        self.firstName = plainObject.firstName
        self.phone = plainObject.phone
    }
}
