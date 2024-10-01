import UIKit

struct HomePayItemViewModel: Equatable, Hashable {
	let id: Int
    let title: String?
    var subtitle: String? = ""
    let image: UIImage?
    var isHighlighted: Bool = false

    init(order: Order, taskIcon: UIImage?) {
		self.id = order.id
        self.title = order.price

        if let dueDate = Date(string: order.dueDate),
            let differenceHour = Calendar.current.dateComponents(
                [.hour],
                from: dueDate,
                to: Date()
            ).hour {
            if abs(differenceHour) > 6 {
                self.isHighlighted = false
                self.subtitle = "\(Localization.localize("home.order.pay.title")) \(PrimeDateFormatter.longOrderTimeString(from: dueDate))"
            } else {
                self.isHighlighted = true
                self.subtitle = "\(Localization.localize("home.order.pay.title")) \(PrimeDateFormatter.shortOrderTimeString(from: dueDate))"
            }
        }

        self.image = taskIcon ?? UIImage(named: "info_icon")
    }
}

extension Order {
    var price: String {
        switch self.currency {
        case "USD":
            return "$\(self.amount)"
        case "EUR":
            return "\(self.amount)\(String.nbsp)€"
        case "RUB":
            return "\(self.amount)\(String.nbsp)\(String.rubleSign)"
        default:
            return "\(self.amount)\(String.nbsp)\(self.currency)"
        }
    }
}
