import UIKit

struct ActiveTaskViewModel: Equatable {
	init(
		taskID: Int,
		title: String?,
		subtitle: String?,
		date: Date?,
		formattedDate: String?,
		isCompleted: Bool,
		hasReservation: Bool,
		image: UIImage?,
		imageLeading: CGFloat = 9,
		imageSize: CGSize = CGSize(width: 36, height: 36),
		routesToTaskDetails: Bool = false,
		task: Task? = nil
	) {
		self.taskID = taskID
		self.title = title
		self.subtitle = subtitle
		self.date = date
		self.formattedDate = formattedDate
		self.isCompleted = isCompleted
		self.hasReservation = hasReservation
		self.image = image
		self.imageLeading = imageLeading
		self.imageSize = imageSize
		self.routesToTaskDetails = routesToTaskDetails
		self.task = task
	}

	let taskID: Int
    let title: String?
    let subtitle: String?
	let date: Date?
    let formattedDate: String?
	let isCompleted: Bool
	var hasReservation: Bool
    let image: UIImage?
	var imageLeading: CGFloat = 9
	var imageSize = CGSize(width: 36, height: 36)
	let routesToTaskDetails: Bool
	let task: Task?

	var isInputAccessory: Bool = false
}
