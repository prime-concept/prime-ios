import Foundation

struct TaskStatisticsResponse: Decodable {
	struct ViewerContainer: Decodable {
		let viewer: Viewer
	}

	struct Viewer: Decodable {
		let typename: String
		let taskStatistics: TaskStatistics

		enum CodingKeys: String, CodingKey {
			case typename = "__typename"
			case taskStatistics
		}
	}

	let data: ViewerContainer
}

struct TaskStatistics: Decodable {
	let total: Int
	let completed: Int
	var active: Int {
		total - completed
	}
}
