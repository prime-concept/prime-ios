import UIKit

struct TasksListPayItemViewModel {
    let title: String?
    var subtitle: String? = ""
    var isHighlighted: Bool = false
    var dueDate: Date?
    var onTap: () -> Void

    init(order: Order, onTapOrder: @escaping (URL?) -> Void) {
        self.title = order.price
        self.onTap = { onTapOrder(order.paymentLink) }

        if let dueDate = Date(string: order.dueDate),
            let differenceHour = Calendar.current.dateComponents(
                [.hour],
                from: dueDate,
                to: Date()
            ).hour {
            self.dueDate = dueDate

            if abs(differenceHour) > 6 {
                self.isHighlighted = false
                self.subtitle = "\(Localization.localize("home.order.pay.title")) \(PrimeDateFormatter.longOrderTimeString(from: dueDate))"
            } else {
                self.isHighlighted = true
                self.subtitle = "\(Localization.localize("home.order.pay.title")) \(PrimeDateFormatter.shortOrderTimeString(from: dueDate))"
            }
        }
    }
}
