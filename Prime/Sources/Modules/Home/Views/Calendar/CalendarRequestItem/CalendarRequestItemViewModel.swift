import UIKit

struct CalendarRequestItemViewModel: Equatable {
	let task: Task!
    let title: String?
    let subtitle: String?
	let location: String?
    let logo: UIImage?
    let hasReservation: Bool

	var date: Date?
	var formattedDate: String? = nil
}
