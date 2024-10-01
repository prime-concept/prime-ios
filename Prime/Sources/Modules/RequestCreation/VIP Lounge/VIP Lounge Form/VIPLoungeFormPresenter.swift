import PromiseKit
import UIKit

protocol VIPLoungeFormPresenterProtocol: AnyObject {
    var route: AviaRoute { get set }
    
    func didLoad()
    func openRouteSelection()
    func openPassengersSelection()
    func selectAirport(for leg: FlightLeg, at index: Int)
    func selectDate(with type: DateType, at index: Int)
    func createTask(completion: @escaping (Int?, Error?) -> Void)
    func addFlight()
    func deleteRow(at index: Int)
}

struct VIPLoungeFormRouteViewModel {
    var arrivalDate: Date?
    var arrivalLocation: Airport?
    var departureDate: Date?
    var departureLocation: Airport?
}

final class VIPLoungeFormPresenter: VIPLoungeFormPresenterProtocol {
    private enum Constants {
        static let singleDatePlaceholder = "avia.single.date.placeholder".localized
        static let departureDatePlaceholder = "avia.departure.date.placeholder".localized
        static let returnDatePlaceholder = "avia.return.date.placeholder".localized
        static let dateFormat = "E, d MMM"
    }
    
    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let localAuthService: LocalAuthServiceProtocol
    private let airportPersistenceService: AirportPersistenceServiceProtocol
    private var airportSearchService: AirportSearchServiceProtocol

    private var passengers: AviaPassengerModel = .vipLounge
    private var routes: [VIPLoungeFormRouteViewModel] = []
    private var multiCity: MultiCityViewModel = .init(rows: [], mode: .edit)
    private let analyticsReporter: AnalyticsReportingServiceProtocol

    private var areRoutesValid: Bool {
        switch route {
        case .oneWay:
            return self.isValidRoutesWith(type: self.vipLoungeType)
        case .roundTrip, .multiCity:
            guard !self.routes.isEmpty else {
                return false
            }
            return self.routes.allSatisfy {
                $0.departureDate != nil && $0.departureLocation != nil && $0.arrivalLocation != nil
            }
        }
    }
        
    var vipLoungeType: VIPLoungeSegmentTypes = .departure {
        didSet {
            self.analyticsReporter.didTapOnChooseRouteType(typeName: vipLoungeType.title)
        }
    }
    
    var route: AviaRoute = .oneWay
    weak var controller: VIPLoungeFormViewControllerProtocol?
    
    // MARK: - life cycle

    init(
        graphQLEndpoint: GraphQLEndpointProtocol,
        analyticsReporter: AnalyticsReportingServiceProtocol,
        localAuthService: LocalAuthServiceProtocol,
        airportPersistenceService: AirportPersistenceServiceProtocol,
        airportSearchService: AirportSearchServiceProtocol
    ) {
        self.graphQLEndpoint = graphQLEndpoint
        self.localAuthService = localAuthService
        self.analyticsReporter = analyticsReporter
        self.airportPersistenceService = airportPersistenceService
        self.airportSearchService = airportSearchService
        getAerotickets()
    }

    // MARK: - view is loaded

    func didLoad() {
        self.controller?.update(self.route)
        self.controller?.update(self.passengers)
        
        let departure = FlightLeg.departure
        let arrival = FlightLeg.arrival
        self.controller?.update(
            departure,
            with: .init(placeholder: departure.placeholder)
        )
        self.controller?.update(
            arrival,
            with: .init(placeholder: arrival.placeholder)
        )
        
        self.setupDates()
        
        let row = MultiCityViewModel.Row(
            origin: .init(placeholder: departure.placeholder),
            destination: .init(placeholder: arrival.placeholder),
            date: .init(placeholder: Constants.singleDatePlaceholder)
        )
        let multiCityViewModel = MultiCityViewModel(rows: [row, row], mode: .edit)
        self.multiCity = multiCityViewModel
        self.controller?.setup(with: multiCityViewModel)
    }

    // MARK: - presetups

    private func getAerotickets() {
        airportPersistenceService
            .retrieve()
            .then {
                self.updateAirports(airports: $0)
                return AeroticketsEndpoint.shared.getAerotickets().promise
            }
            .done {
                self.handle($0)
            }
            .cauterize()
    }

    private func handle(_ aerotickets: Aerotickets) {
        let currentDate = Date()
        guard
            let flight = aerotickets.result?.flatMap({ $0.flights })
                .filter({ $0.departureDateDate?.compare(currentDate) == .orderedDescending })
                .min(by: {
                    guard
                        let date1 = $0.departureDateDate,
                        let date2 = $1.departureDateDate
                    else {
                        return false
                    }
                    return abs(date1.timeIntervalSince(currentDate)) < abs(date2.timeIntervalSince(currentDate))
                })
        else { return }

        self.routes.append(
            VIPLoungeFormRouteViewModel(
                arrivalDate: flight.arrivalDateDateTimezoneless,
                arrivalLocation: queryAirport(with: flight.arrivalAirportId ?? 0),
                departureDate: flight.departureDateDateTimezoneless,
                departureLocation: queryAirport(with: flight.departureAirportId ?? 0)
            )
        )

        self.setupArrivals(of: flight)
        self.setupDeparture(of: flight)

        vipLoungeType = .both
        controller?.updateSegment(with: .both)
    }

    private func setupArrivals(of flight: Aerotickets.Flight) {
        self.controller?.update(
            FlightLeg.arrival,
            with: AirportPickerViewModel(
                value: flight.arrivalAirport,
                placeholder: FlightLeg.departure.placeholder
            )
        )
        self.controller?.update(
            AviaDatePickerModel(
                title: flight.arrivalDateDateTimezoneless?.string(Constants.dateFormat),
                placeholder: Constants.singleDatePlaceholder
            ),
            for: .single
        )
        self.controller?.update(
            AviaDatePickerModel(
                title: flight.arrivalDateDateTimezoneless?.string(Constants.dateFormat),
                placeholder: Constants.returnDatePlaceholder
            ),
            for: .return
        )
    }

    private func setupDeparture(of flight: Aerotickets.Flight) {
        self.controller?.update(
            FlightLeg.departure,
            with: AirportPickerViewModel(
                value: flight.departureAirport,
                placeholder: FlightLeg.arrival.placeholder
            )
        )
        self.controller?.update(
            AviaDatePickerModel(
                title: flight.departureDateDate?.string(Constants.dateFormat),
                placeholder: Constants.departureDatePlaceholder
            ),
            for: .departure
        )
    }

    // MARK: -

    private func queryAirport(with id: Int) -> Airport? {
        airportSearchService.searchAirport(by: id)
    }

    private func updateAirports(airports: [Airport]) {
        airportSearchService.airports = airports
    }

    // MARK: -

    private func isValidRoutesWith(type: VIPLoungeSegmentTypes) -> Bool {
        var isDateValid = false
        var isDepartureLocationValid = false
        var isArrivalLocationValid = false
    
        switch type {
        case .departure:
            isDateValid = self.routes[safe: 0]?.departureDate != nil
            isDepartureLocationValid = self.routes[safe: 0]?.departureLocation != nil
            return isDateValid && isDepartureLocationValid
        case .arrival:
            isDateValid = self.routes[safe: 0]?.departureDate != nil
            isArrivalLocationValid = self.routes[safe: 0]?.arrivalLocation != nil
            return isDateValid && isArrivalLocationValid
        case .both:
            isDateValid = self.routes[safe: 0]?.departureDate != nil
            isDepartureLocationValid = self.routes[safe: 0]?.departureLocation != nil
            isArrivalLocationValid = self.routes[safe: 0]?.arrivalLocation != nil
            return isDateValid && isDepartureLocationValid && isArrivalLocationValid
        }
    }
    
    func openRouteSelection() {
        Notification.post(.messageInputShouldHideKeyboard)
        
        let assembly = AviaRouteSelectionAssembly(preselectedRoute: self.route) { [weak self] selectedRoute in
            guard let self = self, self.route != selectedRoute else {
                return
            }
            
            if let departureLocation = self.routes.first?.departureLocation {
                self.controller?.update(
                    .departure,
                    with: .init(
                        value: departureLocation.name + ", " + departureLocation.city,
                        placeholder: FlightLeg.departure.placeholder
                    )
                )
            }
            
            if let arrivalLocation = self.routes.first?.arrivalLocation {
                self.controller?.update(
                    .arrival,
                    with: .init(
                        value: arrivalLocation.name + ", " + arrivalLocation.city,
                        placeholder: FlightLeg.arrival.placeholder
                    )
                )
            }
            
            let departureDate = self.routes.first?.departureDate
            let returnDate = self.routes[safe: 1]?.departureDate
            
            switch selectedRoute {
            case .oneWay:
                self.controller?.update(
                    .init(
                        title: departureDate?.string("E, d MMM"),
                        placeholder: Constants.singleDatePlaceholder
                    ),
                    for: .single
                )
            case .roundTrip:
                guard var returnDate = returnDate else {
                    self.controller?.update(
                        .init(
                            title: departureDate?.string("E, d MMM"),
                            placeholder: Constants.departureDatePlaceholder
                        ),
                        for: .departure
                    )
                    break
                }
                
                if returnDate < departureDate ?? Date() {
                    returnDate = (departureDate ?? Date()) + 3.days
                    self.routes[1].departureDate = returnDate
                }
                self.controller?.update(
                    .init(
                        title: departureDate?.string("E, d MMM"),
                        placeholder: Constants.departureDatePlaceholder
                    ),
                    for: .departure
                )
                self.controller?.update(
                    .init(
                        title: returnDate.string("E, d MMM"),
                        placeholder: Constants.returnDatePlaceholder
                    ),
                    for: .return
                )
            case .multiCity:
                self.updateMultiCityRow(at: 0)
                if self.route == .roundTrip {
                    self.updateMultiCityRow(at: 1)
                }
                
                // Check dates for validness
                self.validateDates(from: 1)
            }
            
            self.route = selectedRoute
            self.controller?.update(selectedRoute)
        }
        
        let routeController = assembly.make()
        ModalRouter(
            source: self.controller,
            destination: routeController,
            modalPresentationStyle: .formSheet
        ).route()
    }
    
    func openPassengersSelection() {
        Notification.post(.messageInputShouldHideKeyboard)
        
        let assembly = AviaPassengersAssembly(passengers: self.passengers) { [weak self] passengers in
            self?.passengers = passengers
            self?.analyticsReporter.didSelectPassengers(count: "\(self?.passengers.total ?? 0)")
            self?.controller?.update(passengers)
        }
        let passengersController = assembly.make()
        ModalRouter(
            source: self.controller,
            destination: passengersController,
            modalPresentationStyle: .formSheet
        ).route()
    }
    
    func selectAirport(for leg: FlightLeg, at index: Int) {
        Notification.post(.messageInputShouldHideKeyboard)
        
        let assembly = AirportListAssembly(leg: leg) { [weak self] airport in
            guard let self = self else {
                return false
            }

			if airport.id == Airport.artificialAirportId {
				return false
			}
            
            switch leg {
            case .departure:
                if self.routes[safe: index] != nil {
                    self.routes[index].departureLocation = airport
                } else {
                    self.routes.append(.init(departureLocation: airport))
                }
            case .arrival:
                if self.routes[safe: index] != nil {
                    self.routes[index].arrivalLocation = airport
                } else {
                    self.routes.append(.init(arrivalLocation: airport))
                }
            }
            
            switch self.route {
            case .oneWay:
                let placeholder = leg.placeholder

				let value = [airport.name, airport.city].joined(separator: ", ")
                var costText = ""
                if let cost = airport.vipLoungeCost, !cost.isEmpty {
                    costText = "vipLounge.cost.prefix".localized + " \(cost)"
                }

                let model = AirportPickerViewModel(
                    value: value,
                    costValue: costText,
                    placeholder: placeholder
                )
                
                self.analyticsReporter.didSelectAirport(name: value, routе: placeholder, cost: airport.vipLoungeCost)
                self.controller?.update(leg, with: model)
                
                let flipModel = AviaFlipModel(
                    departure: self.routes[safe: index]?.departureLocation?.code ?? "",
                    arrival: self.routes[safe: index]?.arrivalLocation?.code ?? ""
                )
                self.controller?.flip(with: flipModel)
            case .multiCity, .roundTrip:
                break
            }

			return true
        }
        
        let airportsController = assembly.make()
        
        ModalRouter(
            source: self.controller,
            destination: airportsController,
            modalPresentationStyle: .formSheet
        ).route()
    }
    
    func selectDate(with type: DateType, at index: Int) {
        Notification.post(.messageInputShouldHideKeyboard)
        
        let departureDate = self.routes[safe: index]?.departureDate
        let previousDepartureDate = self.routes[safe: index - 1]?.departureDate
        
        // Selected dates
        let selectedMulticityDate = (departureDate ?? previousDepartureDate) ?? Date()
        let selectedDepartureDate = self.route == .multiCity ? selectedMulticityDate : departureDate ?? Date()
        let selectedReturnDate = (self.routes[safe: index + 1]?.departureDate ?? Date() + 3.days).down(to: .day)
        
        let selectedDates: ClosedRange<Date>
        if type == .single {
            selectedDates = selectedDepartureDate.asClosedRange
        } else {
            selectedDates = selectedDepartureDate...selectedReturnDate
        }
        
        let dateController = FSCalendarRangeSelectionViewController(
            monthCount: 12,
            selectionAvailableFrom: Date(),
            isMultipleSelectionAllowed: type != .single,
            selectedDates: selectedDates
        ) { [weak self] dates in
            guard let dates, let self else { return }
            
            let format = "E, d MMM"
            switch type {
            case .single:
                if self.routes[safe: index] != nil {
                    self.routes[index].departureDate = dates.lowerBound
                } else {
                    self.routes.append(.init(departureDate: dates.lowerBound))
                }
        
                if self.route == .oneWay {
                    let dateString = dates.lowerBound.string(format)
                    self.analyticsReporter.didTapOnChooseVipLounge(date: dateString)
                    let model = AviaDatePickerModel(
                        title: dateString,
                        placeholder: Constants.singleDatePlaceholder
                    )
                    self.controller?.update(model, for: .single)
                }
            case .departure, .return:
                break
            }
        }
        ModalRouter(
            source: self.controller,
            destination: dateController,
            modalPresentationStyle: .formSheet
        ).route()
    }
    
    // MARK: - Create task
    
    func createTask(completion: @escaping (Int?, Error?) -> Void) {
        guard
            self.areRoutesValid,
            self.passengers.adults > 0
        else {
            completion(nil, RequestCreationError.blankFields)
            return
        }

        var departure: VipLoungeRoute?
        var landing: VipLoungeRoute?

		func makeVipLoungeRoute(from route: VIPLoungeFormRouteViewModel, airport: Airport?) -> VipLoungeRoute {
            VipLoungeRoute(
                datetime: route.departureDate?.string("dd.MM.yyyy HH:mm") ?? "-",
                airportAndTerminal: "\(airport?.city ?? "")  \(airport?.name ?? "")".trim(),
                departureCityId: route.departureLocation?.id ?? 0,
                landingCityId: route.arrivalLocation?.id ?? 0,
                flightNumber : "-",
                namesAdults: "\(self.passengers.adults)",
                kidNames: "\(self.passengers.children)",
                infantNames: "\(self.passengers.infants)"
            )
		}

        if let route = self.routes.first(where: { $0.departureLocation != nil }) {
            if (vipLoungeType == .departure || vipLoungeType == .both) {
				departure = self.makeVipLoungeRoute(route, route.departureLocation)
            }
        }
        
        if let route = self.routes.first(where: { $0.arrivalLocation != nil }) {
            if (vipLoungeType == .arrival || vipLoungeType == .both) {
				landing = self.makeVipLoungeRoute(route, route.arrivalLocation)
            }
        }

        let vipLoungeInput = VipLoungeInput(
            kind: "VIP",
            transitFlight: nil,
            serviceDescription: self.passengers.isBusinessSelected ? "Бизнес" : "Эконом",
            departure: departure,
            landing: landing
        )
        
        let vipLoungeTaskRequest = TaskInput(
            taskTypeId: TaskTypeEnumeration.vipLounge.id,
            vipLounge: vipLoungeInput
        )

		if let vipLoungeRequestJSON = vipLoungeTaskRequest.jsonString {
            DebugUtils.shared.log(sender: self, "\n\n vipLoungeTaskRequest json \(vipLoungeRequestJSON)")
        }
        
        let variables = [
            "customerId": AnyEncodable(value: localAuthService.user?.username),
            "taskRequest": AnyEncodable(value: vipLoungeTaskRequest)
        ]
        
        self.graphQLEndpoint.request(
            query: GraphQLConstants.create,
            variables: variables
        )
        .promise.done { [weak self] (response: CreateResponse) in
			self?.analyticsReporter.didCreateVipLoungeRequest(taskId: "\(response.taskId)")
			completion(response.taskId, nil)
            DebugUtils.shared.log(
                sender: self,
                "vipLounge task created \(response.taskId)"
            )
        }
        .catch { error in
            AnalyticsReportingService
                .shared.log(
                    name: "[ERROR] \(Swift.type(of: self)) vipLounge request creation failed",
                    parameters: error.asDictionary
                )
            
            completion(nil, RequestCreationError.serverResponseFailure)
            DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING VIP LOUNGE TASK: \(error.localizedDescription)")
        }
    }

	func makeVipLoungeRoute(_ route: VIPLoungeFormRouteViewModel, _ airport: Airport?) -> VipLoungeRoute {
		let dateString = route.departureDate?.string("dd.MM.yyyy HH:mm") ?? "-"

		let isDeparture = self.vipLoungeType == .departure || self.vipLoungeType == .both
		let isArrival = self.vipLoungeType == .arrival || self.vipLoungeType == .both

		let departureLocationId = isDeparture ? route.departureLocation?.cityId ?? 0 : 0
		let arrivalLocationId = isArrival ? route.arrivalLocation?.cityId ?? 0 : 0

        return VipLoungeRoute(
            datetime: dateString,
            airportAndTerminal: "\(airport?.city ?? "")  \(airport?.name ?? "")".trim(),
            departureCityId: departureLocationId,
            landingCityId: arrivalLocationId,
            flightNumber : "-",
            namesAdults: "\(self.passengers.adults)",
            kidNames: "\(self.passengers.children)",
            infantNames: "\(self.passengers.infants)"
        )
	}
    
    func addFlight() {
        guard self.multiCity.rows.count < 10 else {
            return
        }
        
        let route = VIPLoungeFormRouteViewModel()
        self.routes.append(route)
        let defaultRow = MultiCityViewModel.Row(
            origin: .init(placeholder: FlightLeg.departure.placeholder),
            destination: .init(placeholder: FlightLeg.arrival.placeholder),
            date: .init(placeholder: Constants.singleDatePlaceholder),
            shouldShowDeletion: true
        )
        self.multiCity.rows.append(defaultRow)
        self.multiCity.mode = .edit
        self.controller?.update(self.multiCity)
    }
    
    func deleteRow(at index: Int) {
        if self.routes[safe: index] != nil {
            self.routes.remove(at: index)
        }
        self.multiCity.rows.remove(at: index)
        self.multiCity.mode = .edit
        self.controller?.update(self.multiCity)
    }
    
    // MARK: - Helpers
    
    private func setupDates() {
        self.controller?.update(
            .init(placeholder: Constants.singleDatePlaceholder),
            for: .single
        )
        self.controller?.update(
            .init(placeholder: Constants.departureDatePlaceholder),
            for: .departure
        )
        self.controller?.update(
            .init(placeholder: Constants.returnDatePlaceholder),
            for: .return
        )
    }
    
    private func validateDates(from index: Int) {
        guard index > 0 else {
            assertionFailure("NO NEED TO CHECK FROM THE FIRST ITEM!!! Start from the second one. Thank you :)")
            return
        }
        
        guard self.routes[safe: index] != nil else {
            return
        }
        
        self.routes[index...].enumerated().forEach { iterator in
            guard
                let nextDepartureDate = iterator.element.departureDate,
                let previousDepartureDate = self.routes[iterator.offset + index - 1].departureDate,
                nextDepartureDate < previousDepartureDate
            else {
                return
            }
            self.routes[iterator.offset + index].departureDate = previousDepartureDate
            self.multiCity.rows[iterator.offset + index].date.title = previousDepartureDate.string("d MMM")
            self.multiCity.rows[iterator.offset + index].date.subtitle = previousDepartureDate.string("E")
            self.multiCity.mode = .update(iterator.offset + index)
            self.controller?.update(self.multiCity)
        }
    }
    
    private func updateMultiCityRow(at index: Int) {
        guard self.routes[safe: index] != nil && self.multiCity.rows[safe: index] != nil else {
            return
        }
        
        let route = self.routes[index]
        let departureLocation = route.departureLocation
        let arrivalLocation = route.arrivalLocation
        let departureDate = route.departureDate
        
        self.multiCity.rows[index].origin.title = departureLocation?.name
        self.multiCity.rows[index].origin.subtitle = departureLocation?.code
        self.multiCity.rows[index].destination.title = arrivalLocation?.name
        self.multiCity.rows[index].destination.subtitle = arrivalLocation?.code
        self.multiCity.rows[index].date.title = departureDate?.string("d MMM")
        self.multiCity.rows[index].date.subtitle = departureDate?.string("E")
        self.multiCity.mode = .update(index)
        self.controller?.update(self.multiCity)
    }
}
