import Foundation
import RealmSwift

final class OrderPersistent: Object {
    @objc dynamic var amount: String = ""
    @objc dynamic var currency: String = ""
    @objc dynamic var paymentLink: String?
    @objc dynamic var dueDate: String = ""
    @objc dynamic var id: Int = 0
	@objc dynamic var orderStatus: String = ""

    override class func primaryKey() -> String? { "id" }
}

extension Order: RealmObjectConvertible {
    typealias RealmObjectType = OrderPersistent

    init(realmObject: OrderPersistent) {
        self.amount = realmObject.amount
        self.dueDate = realmObject.dueDate
        self.id = realmObject.id
        self.currency = realmObject.currency
		self.paymentLink = realmObject.paymentLink.flatMap {
			URL(string: $0)
		}
		self.orderStatus = realmObject.orderStatus
    }

    var realmObject: OrderPersistent { OrderPersistent(plainObject: self) }
}

extension OrderPersistent {
    convenience init(plainObject: Order) {
        self.init()
        self.amount = plainObject.amount
        self.dueDate = plainObject.dueDate
        self.id = plainObject.id
        self.currency = plainObject.currency
        self.paymentLink = plainObject.paymentLink?.absoluteString
		self.orderStatus = plainObject.orderStatus
    }
}
