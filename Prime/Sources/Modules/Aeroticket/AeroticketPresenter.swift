import Foundation

protocol AeroticketPresenterProtocol {
	func didLoad()
	func share()
	func changeTiket()
}

final class AeroticketPresenter: AeroticketPresenterProtocol {
	private let ticket: Aerotickets.Ticket
	private let flight: Aerotickets.Flight

	var controller: AeroticketViewController?

	init(ticket: Aerotickets.Ticket, flight: Aerotickets.Flight) {
		self.ticket = ticket
		self.flight = flight
	}

	func didLoad() {
		self.updateUI()
	}

	func share() {

	}

	func changeTiket() {

	}
	
	private func updateUI() {
		let flightClass = self.flight.flightClass?.uppercased()

		let viewModel = AeroticketViewModel(
			title: "aerotickets.details".localized, 
			sharingIconImageName: "share_icon",
			sharingAction: {},
			bookingType: "aerotickets.manual.registration".localized,
			card: AeroticketViewModel.Card(
				departure: .init(
					city: self.flight.departureCity^.uppercased(),
					code: self.flight.departureAirportCode^.uppercased(),
					terminal: self.flight.departureTerminal^.uppercased(),
					date: (self.flight.departureDateDateTimezoneless?.string("dd MMM") ?? "").uppercased(),
					time: (self.flight.departureDateDateTimezoneless?.string("HH:mm") ?? "").uppercased()
				),
				arrival: .init(
					city: self.flight.arrivalCity^.uppercased(),
					code: self.flight.arrivalAirportCode^.uppercased(),
					terminal: self.flight.arrivalTerminal^.uppercased(),
					date: (self.flight.arrivalDateDateTimezoneless?.string("dd MMM") ?? "").uppercased(),
					time: (self.flight.arrivalDateDateTimezoneless?.string("HH:mm") ?? "").uppercased()
				),
				flightNumber: self.flight.flightNumber,
				flightIconImageName: "aerotickets_details_flight_icon",
				backgroundImageName: "aerotickets_details_background"
			),
			additionalInfoTitle: "aerotickets.additionalInfo".localized,
			additinalInfo: self.additionalInfo,
			passengersTitle: "aerotickets.passengers".localized,
			passengers: [
				.init(
					iconImageName: "aerotickets_details_passenger_icon",
					fullName: self.ticket.passenger^,
					details: Self.flightClasses[flightClass^] ?? flightClass^
				)
			],
			exchangeTicketTitle: "aerotickets.exchangeActions".localized,
			exchangeTicketAction: { [weak self] in
				self?.changeTiket()
			}
		)

		self.controller?.update(with: viewModel)
	}

	private var additionalInfo: [(String, String)] {
		let checkInStatus = self.flight.checkInStatus
		let routeType = self.ticket.routeTypeEnum ?? .UNKNOWN

		let bookingNumber = self.ticket.airlineData
		let ticketNumberComponents = [self.ticket.airCode, self.ticket.serNumber].compactMap{ $0 }
		var ticketNumber: String? = ticketNumberComponents.joined(separator: " ")
		ticketNumber = (ticketNumber?.isEmpty ?? true) ? nil : ticketNumber

		let additinalInfo: [(String, String?)] = [
			("aerotickets.bookingNumber".localized, bookingNumber),
			("aerotickets.ticketNumber".localized, ticketNumber),
			("aerotickets.carrier".localized, self.flight.airline),
			("aerotickets.seat".localized, self.flight.seat),
			("aerotickets.registrationStatus".localized, Self.registrationStatuses[checkInStatus^] ?? checkInStatus),
			("aerotickets.routeType".localized, Self.routeTypes[routeType]),
			("aerotickets.departureTime".localized, self.flight.departureDateDateTimezoneless?.string("dd/MM/YYYY, HH:mm")),
			("aerotickets.departureGate".localized, self.flight.departureGate),
			("aerotickets.arrivalTime".localized, self.flight.arrivalDateDateTimezoneless?.string("dd/MM/YYYY, HH:mm")),
			("aerotickets.arrivalGate".localized, self.flight.arrivalGate),
			("aerotickets.createdAt".localized, self.ticket.createdAtDate?.string("dd/MM/YYYY, HH:mm")),
			("aerotickets.updatedAt".localized, self.ticket.updatedAtDate?.string("dd/MM/YYYY, HH:mm")),
			("aerotickets.comment".localized, self.flight.comment),
		]
		
		let compactedInfo: [(String, String)] = additinalInfo.compactMap { info in
			if let value = info.1 {
				return (info.0, value)
			}
			return nil
		}

		return compactedInfo
	}
}

fileprivate extension AeroticketPresenter {
	private static let flightClasses = [
		"W": "aerotickets.class.economy".localized,
		"S": "aerotickets.class.economy".localized,
		"Y": "aerotickets.class.economy".localized,
		"B": "aerotickets.class.economy".localized,
		"H": "aerotickets.class.economy".localized,
		"K": "aerotickets.class.economy".localized,
		"L": "aerotickets.class.economy".localized,
		"M": "aerotickets.class.economy".localized,
		"N": "aerotickets.class.economy".localized,
		"Q": "aerotickets.class.economy".localized,
		"T": "aerotickets.class.economy".localized,
		"V": "aerotickets.class.economy".localized,
		"X": "aerotickets.class.economy".localized,
		"R": "aerotickets.class.economy".localized,
		"E": "aerotickets.class.economy".localized,
		"G": "aerotickets.class.economy".localized,
		"U": "aerotickets.class.economy".localized,

		"J": "aerotickets.class.business".localized,
		"C": "aerotickets.class.business".localized,
		"D": "aerotickets.class.business".localized,
		"I": "aerotickets.class.business".localized,
		"Z": "aerotickets.class.business".localized,
		"O": "aerotickets.class.business".localized,

		"F": "aerotickets.class.first".localized,
		"P": "aerotickets.class.first".localized,
		"A": "aerotickets.class.first".localized
	]

	private static let registrationStatuses = [
		"UNREGISTRATED": "aerotickets.registration.UNREGISTRATED".localized,
		"IMPOSSIBLE": "aerotickets.registration.IMPOSSIBLE".localized,
		"REGISTRATED": "aerotickets.registration.REGISTRATED".localized,
		"REGISTRATED_ON_OTHER_SEAT": "aerotickets.registration.REGISTRATED_ON_OTHER_SEAT".localized,
		"REGISTRATED_WITHOUT_BOARDING_PASS": "aerotickets.registration.REGISTRATED_WITHOUT_BOARDING_PASS".localized,
	]

	private static let routeTypes = [
		Aerotickets.Ticket.RouteType.ONE_WAY: "aerotickets.routeType.ONE_WAY".localized,
		Aerotickets.Ticket.RouteType.THERE_AND_BACK: "aerotickets.routeType.THERE_AND_BACK".localized,
		Aerotickets.Ticket.RouteType.SEVERAL_WAYS: "aerotickets.routeType.SEVERAL_WAYS".localized
	]
}
