import Foundation
import PromiseKit
import Alamofire

struct EventsResponse: Decodable {
	let data: [CalendarEvent]
}

protocol EventsEndpointProtocol {
	func getEventsFor(taskIds: [Int]) -> EndpointResponse<EventsResponse>
	func getEventsFor(year: Int, month: Int) -> EndpointResponse<EventsResponse>
	func getEventsFor(year: Int, month: Int, day: Int) -> EndpointResponse<EventsResponse>
}

final class EventsEndpoint: PrimeEndpoint, EventsEndpointProtocol {
	private static let eventsEndpoint = "/events"
	private static let eventsForTasksEndpoint = "/events_for_tasks"
	private let authService: LocalAuthServiceProtocol

	override var usesResponseCache: Bool {
		false
	}

	init(authService: LocalAuthServiceProtocol) {
		self.authService = authService
		super.init()
	}

	required init(
		basePath: String,
		requestAdapter: RequestAdapter? = nil,
		requestRetrier: RequestRetrier? = nil
	) {
		self.authService = LocalAuthService.shared
		super.init(
			basePath: basePath,
			requestAdapter: requestAdapter,
			requestRetrier: requestRetrier
		)
	}

	func getEventsFor(taskIds: [Int]) -> EndpointResponse<EventsResponse> {
		let pathComponent = taskIds.map{ "\($0)" }.joined(separator: ",")
		let endpoint = Self.eventsForTasksEndpoint + "/\(pathComponent)"
		return self.retrieve(endpoint: endpoint)
	}

	private func eventsFor(year: Int, month: Int, day: Int? = nil) -> EndpointResponse<EventsResponse> {
		var endpoint = Self.eventsEndpoint + "/\(year)/\(month)"
		if let day = day {
			endpoint += "/\(day)"
		}
		return self.retrieve(endpoint: endpoint)
	}

	func getEventsFor(year: Int, month: Int) -> EndpointResponse<EventsResponse> {
		self.eventsFor(year: year, month: month, day: nil)
	}

	func getEventsFor(year: Int, month: Int, day: Int) -> EndpointResponse<EventsResponse> {
		self.eventsFor(year: year, month: month, day: day)
	}
}
