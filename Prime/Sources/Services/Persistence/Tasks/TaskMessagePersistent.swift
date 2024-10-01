import Foundation
import RealmSwift
import ChatSDK

final class TaskMessagePersistent: Object {
    @objc dynamic var guid: String = ""
    @objc dynamic var clientId: String = ""
    @objc dynamic var channelId: String = ""
    @objc dynamic var source: String = ""
    @objc dynamic var timestamp = Date(timeIntervalSince1970: 0)
    @objc dynamic var status: String = ""
    @objc dynamic var type: String = ""
    @objc dynamic var content: String = ""
	@objc dynamic var displayName: String = ""

    override class func primaryKey() -> String? { "guid" }
}

extension Message: RealmObjectConvertible {
    typealias RealmObjectType = TaskMessagePersistent

    init(realmObject: TaskMessagePersistent) {
        self.guid = realmObject.guid
        self.clientId = realmObject.clientId
        self.channelId = realmObject.channelId
        self.source = realmObject.source
        self.timestamp = realmObject.timestamp
        self.status = MessageStatus(rawValue: realmObject.status) ?? .deleted
        self.type = MessageType(rawValue: realmObject.type) ?? .text
        self.content = realmObject.content
		self.displayName = realmObject.displayName
    }

    var realmObject: TaskMessagePersistent { TaskMessagePersistent(plainObject: self) }
}

extension TaskMessagePersistent {
    convenience init(plainObject: Message) {
        self.init()
        self.guid = plainObject.guid
        self.clientId = plainObject.clientId
        self.channelId = plainObject.channelId
        self.source = plainObject.source
        self.timestamp = plainObject.timestamp
        self.status = plainObject.status.rawValue
        self.type = plainObject.type.rawValue
        self.content = plainObject.content
		self.displayName = plainObject.displayName
    }
}
