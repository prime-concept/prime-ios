import Foundation
import PromiseKit

class TaskDetailsService {
	// Оставляем shared, это безопасно, тк тут нет стейта кроме эндпоинта
	static let shared = TaskDetailsService()

	private lazy var taskDetailsEndpoint = GraphQLEndpoint()

	func updateDetails(for task: Task) {
		let lang = Locale.primeLanguageCode
		let taskId = task.taskID

		let variables = [
			"lang": AnyEncodable(value: lang),
			"taskId": AnyEncodable(value: taskId)
		]

		self.taskDetailsEndpoint.request(
			query: GraphQLConstants.taskDetails,
			variables: variables
		).promise.done { (response: TasksResponse) in
			var task = task

			guard let newTask = response.data.viewer.tasks.first else {
				return
			}

			task.responsible = newTask.responsible
			task.details = newTask.details

			NotificationCenter.default.post(
				name: .taskWasUpdated,
				object: nil,
				userInfo: ["task": task]
			)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) taskDetailsEndpoint.request failed",
					parameters: error.asDictionary
				)
		}
	}
}
