import Alamofire
import Foundation
import PromiseKit

struct Aerotickets: Codable {
	let result: [Ticket]?

	struct Ticket: Codable {
		enum RouteType: Int, Codable {
			case UNKNOWN = -1
			case ONE_WAY = 0
			case THERE_AND_BACK = 1
			case SEVERAL_WAYS = 2
		}

		let id: Int? // 441756

		let flights: [Flight]

		let taskId: Int?
		let optionId: Int?

		let airCode: String? // "555",
		let airlineData: String? // "237DGT",
		let createdAt: String? // "2023-12-05T15:02:39.832+03:00",
		let customerId: Int? // 268484877,
		let fakeTicket: Bool? // false,
		let flightsCount: Int? // 0,
		let inExchange: String? // "",
		let isActive: Bool? // true,
		let passenger: String? // "KIM/ANNA",
		let routeType: Int? // "ONE_WAY",
		let serNumber: String? // "2469431981",
		let source: String? // "SIRENA",
		let ticketType: String? // "REAL",
		let updatedAt: String? // "2023-12-05T15:04:31.627+03:00"

		var routeTypeEnum: RouteType? {
			guard let routeType = self.routeType else {
				return nil
			}

			return RouteType(rawValue: routeType)
		}

		var createdAtDate: Date? {
			self.createdAt?.date("yyyy-MM-dd'T'HH:mm:ss.SSZ")
		}

		var updatedAtDate: Date? {
			self.updatedAt?.date("yyyy-MM-dd'T'HH:mm:ss.SSZ")
		}
	}

	struct Flight: Codable {
		let id: Int? // 7939,
		let uid: String? // "8ydjzml8njmat8jf5iknugk0h"
		let ticketId: Int? // 441756,

		let airRecLoc: String? // "",
		let airline: String? // "Aeroflot",
		let airlineId: Int? // 14,
		let airplane: String? // "",
		let arrivalAirport: String? // "Пулково",
		let arrivalAirportCode: String? // "LED",
		let arrivalAirportId: Int? // 412,
		let arrivalCity: String? // "Санкт-Петербург",
		let arrivalCountry: String? // "Россия",
		let arrivalDate: String? // "2023-10-19T21:20:00.000+03:00",
		let arrivalGate: String? // "",
		let arrivalTerminal: String? // "",
		let boardingPassFileName: String? // "",
		let carr: String? // "SU",
		let checkInStatus: String? // "UNREGISTRATED",
		let comment: String? // "",
		let departureAirport: String? // "Шереметьево",
		let departureAirportCode: String? // "SVO",
		let departureAirportId: Int? // 2372,
		let departureCity: String? // "Москва",
		let departureCountry: String? // "Россия",
		var departureDate: String? // "2023-10-19T21:20:00.000+03:00",
		let departureDateByMoscowTime: String? // "2023-10-19T21:20:00.000+03:00",
		let departureGate: String? // "",
		let departureTerminal: String? // "",
		let duration: String? // "",
		let fareBasis: String? // "",
		let flight: String? // "28",
		let flightClass: String? // "Y",
		let flightNumber: String? // "SU   28",
		let index: Int? // 0,
		let registrationStart: Bool? // false,
		let seat: String? // "",
	}
}

extension Aerotickets.Flight {
    var arrivalDateDate: Date? {
        self.arrivalDate?.date("yyyy-MM-dd'T'HH:mm:ss.SSZ")
    }

    var departureDateDate: Date? {
        self.departureDate?.date("yyyy-MM-dd'T'HH:mm:ss.SSZ")
    }

    var departureDateByMoscowTimeDate: Date? {
        self.departureDateByMoscowTime?.date("yyyy-MM-dd'T'HH:mm:ss.SSZ")
    }

    var arrivalDateTimezoneless: String? {
        arrivalDate?.replacing(regex: "\\+.+$", with: "")
    }

    var arrivalDateDateTimezoneless: Date? {
        arrivalDateTimezoneless?.date("yyyy-MM-dd'T'HH:mm:ss.SSS")
    }

    var departureDateTimezoneless: String? {
        departureDate?.replacing(regex: "\\+.+$", with: "")
    }

    var departureDateDateTimezoneless: Date? {
        departureDateTimezoneless?.date("yyyy-MM-dd'T'HH:mm:ss.SSS")
    }
}

extension Aerotickets {
	func events(ticketType: String? = "real") -> [CalendarEvent] {
		guard let result = self.result else {
			return []
		}

		var days = 0
		let ticketType = ticketType?.lowercased()
		var events = [CalendarEvent]()

		for ticket in result {
			if ticketType != nil, ticket.ticketType?.lowercased() != ticketType {
				continue
			}

			for flight in ticket.flights {
				var flight = flight
				if UserDefaults[bool: "aeroticketsModernDates"] {
					flight.departureDate = (Date() + days.days).string("yyyy-MM-dd'T'HH:mm:ss.SSZ")
					days += 1
				}
				
				let titleComponents = [flight.departureCity, flight.arrivalCity].compactMap { $0 }
				let title = titleComponents.joined(separator: "-")

				var event = CalendarEvent(
					allDay: false,
					customerId: ticket.customerId ?? -1,
					customerName: ticket.passenger,
					description: "Tiket #\(ticket.serNumber^), flights: \(ticket.flights.count)",
					id: flight.id ?? -1,
					location: flight.departureAirport^,
					startDate: flight.departureDateTimezoneless,
					startDateDay: flight.departureDateDateTimezoneless?.down(to: .day),
					startDateDate: flight.departureDateDateTimezoneless,
					taskId: -1,
					taskInfoId: -1,
					taskTypeId: TaskTypeEnumeration.aeroflotAvia.id,
					title: title
				)
				
				event.userInfo = [
					"ticket": ticket,
					"flight": flight
				]

				var task = Task(
					customerID: -1,
					id: Task.aeroticketFlightTaskID,
					taskID: Task.aeroticketFlightTaskID,
					updatedAt: Date()
				)

				task.updateCustomID("\(ticket.id^)_\(flight.uid^)")
				task.events = [event]
				event.task = task

				events.append(event)
			}
		}

		return events
	}
}

protocol AeroticketsEndpointProtocol: CachingEnpointProtocol {
	func getAerotickets() -> EndpointResponse<Aerotickets>
}

final class AeroticketsEndpoint: PrimeEndpoint, AeroticketsEndpointProtocol {
	private static let aeroticketsEndpoint = "/me/aerotickets"
	private let authService: LocalAuthServiceProtocol

	// Оставляем shared, это безопасно, тк тут нет стейта зависимого от сессии юзера
	static let shared = AeroticketsEndpoint(authService: LocalAuthService.shared)

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

	func getAerotickets() -> EndpointResponse<Aerotickets> {
		self.retrieve(endpoint: Self.aeroticketsEndpoint)
	}
}
