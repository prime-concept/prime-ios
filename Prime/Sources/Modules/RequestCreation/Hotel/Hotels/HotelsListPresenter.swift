import Foundation

protocol HotelsListPresenterProtocol {
    func search(by query: String)
    func didSelectHotel(with id: Int)
    func didSelectCity(with id: Int)
    func didSelectCategoryFilter(type: CategoryFilter)
}

final class HotelsListPresenter: HotelsListPresenterProtocol {
    private lazy var searchDebouncer: Debouncer = {
        let debouncer = Debouncer(timeout: 1.3) { [weak self] in
            self?.performSearch()
        }
        return debouncer
    }()

    private let analyticsReporter: AnalyticsReportingServiceProtocol
    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let onSelect: (Hotel?, HotelCity?) -> Void
    private var hotels: [Hotel] = []
    private var cities: Set<HotelCity> = []
    private var query: String = ""

    weak var controller: HotelsListViewControllerProtocol?

    init(
        onSelect: @escaping (Hotel?, HotelCity?) -> Void,
        graphQLEndpoint: GraphQLEndpointProtocol,
        analyticsRepoter: AnalyticsReportingServiceProtocol
    ) {
        self.onSelect = onSelect
        self.graphQLEndpoint = graphQLEndpoint
        self.analyticsReporter = analyticsRepoter
    }

    func search(by query: String) {
        self.hotels = []
        self.cities = []
        self.query = query
        self.searchDebouncer.reset()
    }

    func didSelectHotel(with id: Int) {
		let hotel = self.hotels.first{ $0.id == id }
        guard let hotel = hotel else {
            DebugUtils.shared.alert(sender: self, "No hotel with ID: \(id)")
            return
        }
        self.onSelect(hotel, nil)
        self.analyticsReporter.didTapOnFilteredItemEvent(mode: AnalyticsEvents.HotelsList.FilterMode.hotels(id))
    }

    func didSelectCity(with id: Int) {
		let city = self.cities.first { $0.id == id }
        guard let city = city else {
            DebugUtils.shared.alert(sender: self, "No city with ID: \(id)")
            return
        }
        self.onSelect(nil, city)
        self.analyticsReporter.didTapOnFilteredItemEvent(mode: AnalyticsEvents.HotelsList.FilterMode.cities(id))
    }
    
    func didSelectCategoryFilter(type: CategoryFilter) {
        switch type {
        case .top:
            self.analyticsReporter.didTapOnFilterTopCategory()
        case .hotels:
            self.analyticsReporter.didTapOnFilterHotelsCategory()
        case .cities:
            self.analyticsReporter.didTapOnFilterCitiesCategory()
        }
    }

    // MARK: - Helpers

    private func performSearch() {
        if self.query.isEmpty {
            let listViewModel = HotelsListViewModel(hotels: [], cities: [])
            self.controller?.set(list: listViewModel)
            return
        }

		if self.query.count < 3 {
			return
		}

        self.fetch(queue: self.query)
        self.analyticsReporter.didTapOnSearchItems(with: self.query)
    }

    private func fetch(queue: String) {
        let completion: ([Hotel]) -> Void = { [weak self] hotels in
            self.some { (self) in
                self.hotels = hotels.sorted()
                let cities = hotels.compactMap { hotel -> HotelCity? in
                    guard let city = hotel.city,
                          city.id != nil,
                          city.name != nil,
                          city.country != nil else {
                        return nil
                    }
                    return city
                }
                self.cities = Set(cities)
                let listViewModel = HotelsListViewModel(
                    hotels: self.hotels,
                    cities: self.cities,
                    isSearchActive: true
                )
                self.controller?.set(list: listViewModel)
            }
        }

        self.controller?.showLoadingIndicator()
        self.graphQLEndpoint.request(
            query: GraphQLConstants.hotels,
            variables: [
				"lang": AnyEncodable(value: Locale.primeLanguageCode),
                "type": AnyEncodable(value: 44),
                "q": AnyEncodable(value: query)
            ]
        )
		.promise
        .done { (response: HotelsResponse) in
            completion(response.hotels)
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) hotels list fetch failed",
					parameters: error.asDictionary
				)

            AlertPresenter.alertCommonError(error)
            DebugUtils.shared.alert(sender: self, "ERROR FETCHING HOTELS \(error)")
        }
        .finally { [weak self] in
            self?.controller?.hideLoadingIndicator()
        }
    }
}
