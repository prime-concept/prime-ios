import Foundation
import PromiseKit

final class AnyCitySelectionPresenter: CatalogItemSelectionPresenterProtocol {
	weak var controller: CatalogItemSelectionControllerProtocol?

	private let qraphQLEndpoint: GraphQLEndpointProtocol
	private var selectedCityId: Int?
	private let onSelect: ((City) -> Void)
	private var cities: [City] = []
	private var filteredCities: [City] = []
	private var search: String = ""
	private lazy var searchDebouncer: Debouncer = {
		let debouncer = Debouncer(timeout: 1.3) { [weak self] in
			self?.performSearch()
		}
		return debouncer
	}()

	init(
		qraphQLEndpoint: GraphQLEndpointProtocol,
		selectedCityId: Int?,
		onSelect: @escaping ((City) -> Void)
	) {
		self.qraphQLEndpoint = qraphQLEndpoint
		self.selectedCityId = selectedCityId
		self.onSelect = onSelect
	}

	func didLoad() {
		self.fetch()
	}

	func search(by string: String) {
		self.cities = []
		self.search = string
		self.searchDebouncer.reset()
	}

	func performSearch() {
		if self.search.isEmpty {
			self.filteredCities = self.cities
			self.controller?.reload()
			return
		}

		self.fetch(queue: self.search)
	}

	func numberOfItems() -> Int {
		self.filteredCities.count
	}

	func item(at index: Int) -> CatalogItemRepresentable {
		let city = self.filteredCities[index]
		return CityViewModel(
			name: city.name,
            selected: city.id == self.selectedCityId,
			description: city.country?.name
		)
	}

	func select(at index: Int) {
        self.selectedCityId = filteredCities[index].id
	}

	func apply() {
        self.selectedCityId.some { id in
            let city = self.cities.first { $0.id == id }
            city.some { city in
                self.onSelect(city)
            }
        }
	}

	// MARK: - Private

	private func fetch(queue: String? = nil) {
		let completion: ([City]) -> Void = { [weak self] cities in
			self?.filteredCities = cities
			self?.controller?.reload()
			self?.controller?.hideLoading()
		}

		guard let queue = queue, !queue.isEmpty else {
			completion([])
			return
		}

		self.controller?.showLoading()
		self.qraphQLEndpoint.request(
			query: GraphQLConstants.citiesWithCountries,
			variables: [
				"q": AnyEncodable(value: queue),
				"lang": AnyEncodable(value: Locale.primeLanguageCode)
			]
		).promise
		.done { [weak self] (response: CitiesWithCountries) in
			self?.cities = response.cities
			completion(response.cities)
		}
		.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) cities list fetch failed",
					parameters: error.asDictionary
				)

			self.controller?.hideLoading()
			AlertPresenter.alertCommonError(error)
			DebugUtils.shared.alert(sender: self, "ERROR FETCH cities \(error)")
		}
	}
}

struct CitiesWithCountries: Decodable {
	let data: [String: [String: [City]]]
	var cities: [City] {
		data["dict"]?["cities"] ?? []
	}
}
