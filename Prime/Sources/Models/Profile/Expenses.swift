import Foundation

struct Transactions: Codable {
    let data: [Datum]

    struct Datum: Codable {
        let transactions: [Transaction]
    }
}

struct Transaction: Codable {
    let id: Int
	let period: String
	let toReport, type: String?
    let category: String?
    let balanceBefore, amount, balanceAfter: Double
    let currency: String
    let directPayment: Bool
    let exchangeRate: Double?
    let expense: Bool
    let taskID: Int?
    let taskInfoID, taskTypeID, optionID: Int?

    enum CodingKeys: String, CodingKey {
        case id, period, toReport, type, category, balanceBefore, amount,
             balanceAfter, currency, directPayment, exchangeRate, expense
        case taskID = "taskId"
        case taskInfoID = "taskInfoId"
        case taskTypeID = "taskTypeId"
        case optionID = "optionId"
    }
}
