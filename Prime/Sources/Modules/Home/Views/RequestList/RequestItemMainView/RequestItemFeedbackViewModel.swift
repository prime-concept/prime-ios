import Foundation

struct RequestItemFeedbackViewModel: Equatable, Hashable {
	internal init(title: String, rating: Int = 0, taskCompleted: Bool) {
		self.title = title
		self.rating = rating
		self.taskCompleted = taskCompleted
	}

	let title: String
	let rating: Int
	let taskCompleted: Bool
}
