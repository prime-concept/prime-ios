import Foundation

struct AeroticketViewModel {
	struct Card {
		struct Airport {
			let city: String?
			let code: String?
			let terminal: String?

			let date: String?
			let time: String?
		}

		let departure: Airport
		let arrival: Airport

		let flightNumber: String?

		let flightIconImageName: String
		let backgroundImageName: String
	}

	struct Passenger {
		let iconImageName: String
		let fullName: String?
		let details: String?
	}

	let title: String
	let sharingIconImageName: String
	var sharingAction: (() -> Void)?

	let bookingType: String?
	let card: Card

	let additionalInfoTitle: String
	let additinalInfo: [(String, String)]

	let passengersTitle: String
	let passengers: [Passenger]

	let exchangeTicketTitle: String
	let exchangeTicketAction: (() -> Void)?
}
