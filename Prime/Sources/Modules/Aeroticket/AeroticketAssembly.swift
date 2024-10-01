import UIKit

final class AeroticketAssembly: Assembly {
	private let ticket: Aerotickets.Ticket
	private let flight: Aerotickets.Flight

	init(ticket: Aerotickets.Ticket, flight: Aerotickets.Flight) {
		self.ticket = ticket
		self.flight = flight
	}

	func make() -> UIViewController {
		let presenter = AeroticketPresenter(
			ticket: self.ticket,
			flight: self.flight
		)

		let controller = AeroticketViewController(presenter: presenter)
		presenter.controller = controller

		return controller
	}
}
