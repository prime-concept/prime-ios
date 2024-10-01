struct DiscountsResponse: Codable {
	let data: [Discount]?
}

struct Discount: Codable {
    var id: Int?
    var type: DiscountType?
    var cardNumber: String?
    var issueDate: String?
    var expiryDate: String?
    var password: String?
    var description: String?
}

struct DiscountTypeResponse: Codable {
    let data: [DiscountType]
}

struct DiscountType: Codable, Equatable {
    let id: Int?
    let name: String?
    let position: Int?
    let color: String?
    let logoUrl: String?
}

struct PaymentCard {
    let thumb: String
}

struct Discounts: Codable {
    let data: [Discount]?
}

struct DiscountTypes: Codable {
    let data: [DiscountType]?
}
