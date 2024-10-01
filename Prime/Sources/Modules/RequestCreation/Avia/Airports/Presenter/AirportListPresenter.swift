import Foundation
import PromiseKit

protocol AirportListPresenterProtocol {
    func setQuery(query: String)
    func didLoad()
	func didSelectAirport(_ selection: AirportSelection) -> Bool
}

enum FlightLeg {
    case departure, arrival

    var placeholder: String {
        switch self {
        case .departure:
            return "avia.departure.placeholder".localized
        case .arrival:
            return "avia.arrival.placeholder".localized
        }
    }
}

enum AirportSelection {
	case airport(id: Int)
	case city(name: String)
}

final class AirportListPresenter: AirportListPresenterProtocol {
    private let leg: FlightLeg

    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let airportPersistenceService: AirportPersistenceServiceProtocol
    private var airportSearchService: AirportSearchServiceProtocol
    private let mayTapOnCityHub: Bool

    weak var controller: AirportListViewProtocol?
    private let onSelect: (Airport) -> Bool

    private var query: String = ""
    private var airports: [Airport] = []

    init(
        leg: FlightLeg,
        mayTapOnCityHub: Bool,
        onSelect: @escaping (Airport) -> Bool,
        graphQLEndpoint: GraphQLEndpointProtocol,
        airportPersistenceService: AirportPersistenceServiceProtocol,
        airportSearchService: AirportSearchServiceProtocol
    ) {
        self.leg = leg
        self.mayTapOnCityHub = mayTapOnCityHub
        self.onSelect = onSelect
        self.graphQLEndpoint = graphQLEndpoint
        self.airportPersistenceService = airportPersistenceService
        self.airportSearchService = airportSearchService
    }

	private var languageWasChanged: Bool {
		let lang = Locale.primeLanguageCode

		let previousLang = UserDefaults[string: "AirportListPresenter.lang"]

		return previousLang != lang
	}

	private var airportsRequestVariables: [String: AnyEncodable] {
		let lang = Locale.primeLanguageCode

		defer {
			UserDefaults[string: "AirportListPresenter.lang"] = lang
		}

		let lastUpdatedAt = self.languageWasChanged ? 0 : self.airportPersistenceService.lastUpdatedAt

		return [
			"lastUpdatedAt": AnyEncodable(value: lastUpdatedAt),
			"lang": AnyEncodable(value: lang)
		]
	}

    func didLoad() {
		Notification.onReceive(.loggedOut, .shouldClearCache) { [weak self] _ in
			UserDefaults[string: "AirportListPresenter.lang"] = nil
			self?.airportPersistenceService.delete()
		}

		if self.languageWasChanged {
			self.airportPersistenceService.delete()
		}

        //Get cached data first, display, then update it and display again if anything updated
        self.airportPersistenceService.retrieve().then { airports in
            self.updateAirports(airports: airports)
        }.then { generatedViewModel -> Promise<AirportsResponse> in
            if generatedViewModel.airportLists.isEmpty {
				(self.controller as? UIViewController)?.showLoadingIndicator()
			} else {
                var viewModel = generatedViewModel
                viewModel.mayTapOnCityHub = self.mayTapOnCityHub
				self.controller?.set(viewModel: viewModel)
			}

			let variables = self.airportsRequestVariables

            return self.graphQLEndpoint.request(
                query: GraphQLConstants.airports,
				variables: variables
            ).promise
        }.then { (response: AirportsResponse) -> Guarantee<[Airport]> in
			(self.controller as? UIViewController)?.hideLoadingIndicator()

            let updatedAirports = response.data.dict.airports
            if updatedAirports.isEmpty {
                throw AirportLoadingFakeError.alreadyActualViewModel
            }
            self.save(airports: updatedAirports)
            return self.airportPersistenceService.retrieve()
        }.then { airports in
            self.updateAirports(airports: airports)
		}.done(on: .main) { generatedViewModel in
            var viewModel = generatedViewModel
            viewModel.mayTapOnCityHub = self.mayTapOnCityHub
            self.controller?.set(viewModel: viewModel)
        }.catch { error in
            if let error = error as? AirportLoadingFakeError,
                error == .alreadyActualViewModel {
                DebugUtils.shared.alert(sender: self, "No need to update airports view from internet data")
            } else {
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) fetch failed",
						parameters: error.asDictionary
					)

				AlertPresenter.alertCommonError(error)
                DebugUtils.shared.alert(sender: self, "ERROR WHILE FETCHING AIRPORTS: \(error.localizedDescription)")
            }
		}.finally {
			(self.controller as? UIViewController)?.hideLoadingIndicator()
		}
    }

    func didSelectAirport(_ selection: AirportSelection) -> Bool {
		var result = false

		switch selection {
			case .airport(let id):
				guard let airport = self.airports.first(where: { $0.id == id }) else {
					return false
				}
				
				result = self.onSelect(airport)
				self.airportSearchService.setSearched(airport: airport)
			case .city(let name):
				let airport = Airport(
					id: Airport.artificialAirportId,
					altCountryName: "",
					altCityName: name,
					isHub: true,
					city: name,
					cityId: Airport.artificialCityId,
					code: "",
					country: "",
					name: ""
				)
				result = self.onSelect(airport)
		}

		return result
    }

	private lazy var airportsSearchQueue = DispatchQueue(label: "\(Self.self).airportsSearchQueue")
	private lazy var airportSearchDebouncer = Debouncer(timeout: 0.5) { [weak self] in
		guard let self else { return }

		self.generateViewModel(airports: self.airports, query: self.query).done(on: .main) { generatedViewModel in
            
            var viewModel = generatedViewModel
            viewModel.mayTapOnCityHub = self.mayTapOnCityHub
			self.controller?.set(viewModel: viewModel)
		}.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) generateViewModel failed",
					parameters: error.asDictionary.appending("query", self.query)
				)
		}
	}

    func setQuery(query: String) {
        self.query = query
		self.airportSearchDebouncer.reset()
    }

    private func save(airports: [Airport]) {
        self.airportPersistenceService.save(airports: airports).done { [weak self] _ in
            DebugUtils.shared.log(sender: self, "Airports saved")
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) save failed",
					parameters: error.asDictionary
				)
            DebugUtils.shared.alert(sender: self, "Error saving airports \(error.localizedDescription)")
        }
    }

    private func updateAirports(airports: [Airport]) -> Guarantee<AirportListsViewModel> {
        self.airports = airports
        return self.generateViewModel(airports: airports, query: self.query)
    }

	private func generateViewModel(airports: [Airport], query: String) -> Guarantee<AirportListsViewModel> {
		Guarantee { [weak self] seal in
			guard let self else { return }

			self.airportSearchService.airports = airports
			self.airportSearchService.getClosestAirports().done { closestAirports in
				self.queryAirportsAndPopulateViewModel(query, closestAirports) { viewModel in
					seal(viewModel)
				}
			}.catch { error in
				self.queryAirportsAndPopulateViewModel(query, []) { viewModel in
					seal(viewModel)
				}

				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) closest airport fetch failed",
						parameters: error.asDictionary
					)
			}
		}
	}

	private func queryAirportsAndPopulateViewModel(
		_ query: String,
		_ closestAirports: [(Airport, Distance)],
		_ completion: ((AirportListsViewModel) -> Void)? = nil
	) {
		self.airportsSearchQueue.async {
			let queriedAirports = query.isEmpty ? [] : self.airportSearchService.queryAirports(query: query)
			let closestAirports = query.isEmpty ? closestAirports : []

			completion?(
				AirportListsViewModel(
					queriedAirports: queriedAirports,
					airportsNear: closestAirports
				)
			)
		}
	}

    enum AirportLoadingFakeError: Error {
        case alreadyActualViewModel
    }
}
