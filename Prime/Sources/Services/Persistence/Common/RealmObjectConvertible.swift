import Foundation
import RealmSwift

protocol RealmObjectConvertible {
    associatedtype RealmObjectType: Object

    init(realmObject: RealmObjectType)
    var realmObject: RealmObjectType { get }
}
