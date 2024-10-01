import Foundation

struct OrdersSearchFilter: Encodable {
    let paid: Bool
}

struct Order: Codable {
	/**
	 0 - Создано CREATED
	 1 - Требует оплаты REQUIRES_PAYMENT
	 2 - Частично оплачено PARTIALLY_PAID
	 3 - Оплачено PAID
	 4 - Отмена CANCELED,
	 5 - Деньги зарезервированы HOLD
	 */
	enum Status: String {
		case created = "0"
		case requiresPayment = "1"
		case partiallyPaid = "2"
		case paid = "3"
		case canceled = "4"
		case hold = "5"
	}

    let amount: String
    let currency: String
    let dueDate: String
    let id: Int
    let paymentLink: URL?

	let orderStatus: String
	var status: Status? {
		Status.init(rawValue: self.orderStatus)
	}
}

extension Order {
	var isWaitingForPayment: Bool {
		guard Date(string: self.dueDate) ?>= Date() else {
			return false
		}
		guard self.status == .requiresPayment || self.status == .created else {
			return false
		}
		return self.paymentLink != nil
	}
}
