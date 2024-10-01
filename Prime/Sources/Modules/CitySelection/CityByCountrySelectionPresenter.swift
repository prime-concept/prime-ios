import Foundation
import PromiseKit

final class CityByCountrySelectionPresenter: CatalogItemSelectionPresenterProtocol {
	weak var controller: CatalogItemSelectionControllerProtocol?

	private let qraphQLEndpoint: GraphQLEndpointProtocol
	private var selectedCity: City?
	private var country: Country
	private let onSelect: ((City) -> Void)
	private var cities: [City] = []
	private var filteredCities: [City] = []
	private var search: String?

	init(
		qraphQLEndpoint: GraphQLEndpointProtocol,
		selectedCity: City?,
		country: Country,
		onSelect: @escaping ((City) -> Void)
	) {
		self.qraphQLEndpoint = qraphQLEndpoint
		self.selectedCity = selectedCity
		self.country = country
		self.onSelect = onSelect
	}

	func didLoad() {
		self.fetch()
	}

	func search(by string: String) {
		self.search = string

		if string.isEmpty {
			self.filteredCities = self.cities
		} else {
			self.filteredCities = self.cities.filter {
				$0.name.range(of: string, options: .caseInsensitive) != nil
			}
		}
		self.controller?.reload()
	}

	func numberOfItems() -> Int {
		self.filteredCities.count
	}

	func item(at index: Int) -> CatalogItemRepresentable {
		let country = self.filteredCities[index]
		return CityViewModel(
			name: country.name,
			selected: country == self.selectedCity,
			description: nil
		)
	}

	func select(at index: Int) {
		self.selectedCity = filteredCities[index]
	}

	func apply() {
		self.selectedCity.flatMap { self.onSelect($0) }
	}

	// MARK: - Private

	private func fetch() {
		self.controller?.showLoading()

		self.qraphQLEndpoint.request(
			query: GraphQLConstants.countriesWithCities,
			variables: [
				"lang": AnyEncodable(value: Locale.primeLanguageCode),
				"q": AnyEncodable(value: self.country.name)
			]
		).promise
		.done { [weak self] (response: Countries) in
			guard let self = self else {
				return
			}

            if let cities = response.countries.first?.cities {
				self.cities = cities
			}
			self.filteredCities = self.cities
			self.controller?.reload()
			self.controller?.hideLoading()
		}
		.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) CitiesByCountry fetch failed",
					parameters: error.asDictionary
				)

			self.controller?.hideLoading()
			AlertPresenter.alertCommonError(error)
			DebugUtils.shared.alert(sender: self, "ERROR FETCH CITIES \(error)")
		}
	}
}

struct CityViewModel: CatalogItemRepresentable {
	let name: String
	let selected: Bool
	let description: String?
}

