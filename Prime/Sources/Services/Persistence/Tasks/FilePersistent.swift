import Foundation
import RealmSwift

final class FilePersistent: Object {
	@objc dynamic var uid: String = ""
	@objc dynamic var width: Int = -1
	@objc dynamic var height: Int = -1
	@objc dynamic var fileName: String = ""
	@objc dynamic var contentType: String = ""
	@objc dynamic var size: Int = -1
	@objc dynamic var _description: String? = nil

	override class func primaryKey() -> String? { "uid" }
}

extension FilesResponse.File: RealmObjectConvertible {
	typealias RealmObjectType = FilePersistent

	init(realmObject: FilePersistent) {
		self.uid = realmObject.uid
		self.width = realmObject.width
		self.height = realmObject.height
		self.fileName = realmObject.fileName
		self.contentType = realmObject.contentType
		self.size = realmObject.size
		self.description = realmObject._description
	}

	var realmObject: FilePersistent { FilePersistent(plainObject: self) }
}

extension FilePersistent {
	convenience init(plainObject: FilesResponse.File) {
		self.init()
		self.uid = plainObject.uid
		self.width = plainObject.width ?? -1
		self.height = plainObject.height ?? -1
		self.fileName = plainObject.fileName
		self.contentType = plainObject.contentType
		self.size = plainObject.size
		self._description = plainObject.description
	}
}
