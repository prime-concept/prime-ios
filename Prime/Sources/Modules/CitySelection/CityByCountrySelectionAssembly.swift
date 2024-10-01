import UIKit

final class CityByCountrySelectionAssembly: Assembly {
	private let selectedCity: City?
	private let country: Country
	private let onSelect: (City) -> Void

	private(set) var scrollView: UIScrollView?

	init(selectedCity: City?, country: Country, onSelect: @escaping (City) -> Void) {
		self.selectedCity = selectedCity
		self.country = country
		self.onSelect = onSelect
	}

	func make() -> UIViewController {
		let presenter = CityByCountrySelectionPresenter(
			qraphQLEndpoint: GraphQLEndpoint(),
			selectedCity: self.selectedCity,
			country: self.country,
			onSelect: self.onSelect
		)
		let controller = CatalogItemSelectionViewController(
			presenter: presenter
		)
		presenter.controller = controller
		self.scrollView = controller.scrollView
		return controller
	}
}
