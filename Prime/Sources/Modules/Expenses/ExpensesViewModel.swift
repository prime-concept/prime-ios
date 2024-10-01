import Foundation
import UIKit

struct ExpensesViewModel {
    let type: String
    let category: String
    let amount: String
    let image: UIImage?
    let date: Date?
}

extension ExpensesViewModel {
    static func makeAsLoyalty(from transaction: Transaction) -> ExpensesViewModel {
        let type = transaction.type
        let category = transaction.category
		let amount = transaction.amount.string(format: "%0.2f")
        var image: UIImage?
        if let taskTypeID = transaction.taskTypeID {
			image = TaskType.image(for: taskTypeID)
        } else {
            image = UIImage(named: "other_icon")
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: transaction.period)
        return ExpensesViewModel(
			type: type ?? "",
			category: category ?? "",
			amount: amount,
			image: image,
			date: date
		)
    }
}
