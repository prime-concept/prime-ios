import UIKit

protocol AviaFormPresenterProtocol: AnyObject {
    var route: AviaRoute { get set }

    func didLoad()
    func openRouteSelection()
    func openPassengersSelection()
    func selectAirport(for leg: FlightLeg, at index: Int)
    func selectDate(with type: DateType, at index: Int)
    func flipAirports()
    func createTask(completion: @escaping (Int?, Error?) -> Void)
    func addFlight()
    func deleteRow(at index: Int)
}

struct RouteViewModel {
    var arrivalDate: Date?
    var arrivalLocation: Airport?
    var departureDate: Date?
    var departureLocation: Airport?
}

final class AviaFormPresenter: AviaFormPresenterProtocol {
    private enum Constants {
        static let singleDatePlaceholder = "avia.single.date.placeholder".localized
        static let departureDatePlaceholder = "avia.departure.date.placeholder".localized
        static let returnDatePlaceholder = "avia.return.date.placeholder".localized
    }

    private let analyticsReporter: AnalyticsReportingService
    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let localAuthService: LocalAuthServiceProtocol

    private var passengers: AviaPassengerModel = .default
    private var routes: [RouteViewModel] = []
    private var multiCity: MultiCityViewModel = .init(rows: [], mode: .edit)

    private var areRoutesValid: Bool {
        switch route {
        case .oneWay:
            let isDateValid = self.routes[safe: 0]?.departureDate != nil
            let isDepartureLocationValid = self.routes[safe: 0]?.departureLocation != nil
            let isArrivalLocationValid = self.routes[safe: 0]?.arrivalLocation != nil
            return isDateValid && isDepartureLocationValid && isArrivalLocationValid
        case .roundTrip, .multiCity:
            guard !self.routes.isEmpty else {
                return false
            }

            return self.routes.allSatisfy {
                $0.departureDate != nil && $0.departureLocation != nil && $0.arrivalLocation != nil
            }
        }
    }

    var route: AviaRoute = .default
    weak var controller: AviaFormViewControllerProtocol?

    init(
        graphQLEndpoint: GraphQLEndpointProtocol,
        localAuthService: LocalAuthServiceProtocol,
        analyticsReporter: AnalyticsReportingService
    ) {
        self.graphQLEndpoint = graphQLEndpoint
        self.localAuthService = localAuthService
        self.analyticsReporter = analyticsReporter
    }

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

    func openRouteSelection() {
        Notification.post(.messageInputShouldHideKeyboard)

        let assembly = AviaRouteSelectionAssembly(preselectedRoute: self.route) { [weak self] selectedRoute in
            guard let self, self.route != selectedRoute else { return }

            if let departureLocation = self.routes.first?.departureLocation {
                let value = departureLocation.isHub^
                ? departureLocation.city
                : [departureLocation.name, departureLocation.city].joined(", ")
				
                
                self.controller?.update(
                    .departure,
                    with: .init(
                        value: value,
                        placeholder: FlightLeg.departure.placeholder
                    )
                )
            }

            if let arrivalLocation = self.routes.first?.arrivalLocation {
                let value = arrivalLocation.isHub^
                ? arrivalLocation.city
				: [arrivalLocation.name, arrivalLocation.city].joined(", ")
                
                self.controller?.update(
                    .arrival,
                    with: .init(
                        value: value,
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

            self.analyticsReporter.didSelectAvia(route: selectedRoute.title)
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

        self.analyticsReporter.didOpenAirportListForm(leg: leg.placeholder)
        
        let assembly = AirportListAssembly(leg: leg, mayTapOnCityHub: true) { [weak self] airport in

            guard let self else { return false }

            self.analyticsReporter.didSelect(airport: airport.name, leg: leg.placeholder)
            switch leg {
            case .departure:
                if self.routes[safe: index] != nil {
                    self.routes[index].departureLocation = airport
                } else {
                    self.routes.append(.init(departureLocation: airport))
                }
                if self.route == .roundTrip {
                    if self.routes[safe: index + 1] != nil {
                        self.routes[index + 1].arrivalLocation = airport
                    } else {
                        self.routes.append(.init(arrivalLocation: airport))
                    }
                }
            case .arrival:
                if self.routes[safe: index] != nil {
                    self.routes[index].arrivalLocation = airport
                } else {
                    self.routes.append(.init(arrivalLocation: airport))
                }
                if self.route == .roundTrip {
                    if self.routes[safe: index + 1] != nil {
                        self.routes[index + 1].departureLocation = airport
                    } else {
                        self.routes.append(.init(departureLocation: airport))
                    }
                }

                if self.route == .multiCity && self.routes[safe: index + 1] != nil {
                    self.routes[index + 1].departureLocation = airport
                }
            }

            switch self.route {
            case .oneWay, .roundTrip:
                let placeholder = leg.placeholder
                
                let value = "\(airport.city), " + airport.country
                let model = AirportPickerViewModel(value: value, placeholder: placeholder)
                self.controller?.update(leg, with: model)

                let flipModel = AviaFlipModel(
                    departure: self.routes[safe: index]?.departureLocation?.code ?? "",
                    arrival: self.routes[safe: index]?.arrivalLocation?.code ?? ""
                )
                self.controller?.flip(with: flipModel)
            case .multiCity:
                if leg == .departure {
                    self.multiCity.rows[index].origin.title = airport.isHub^ ? airport.city : airport.name
                    self.multiCity.rows[index].origin.subtitle = airport.code
                } else {
                    self.multiCity.rows[index].destination.title = airport.isHub^ ? airport.city : airport.name
                    self.multiCity.rows[index].destination.subtitle = airport.code
                    if self.multiCity.rows[safe: index + 1] != nil {
                        self.multiCity.rows[index + 1].origin.title = airport.isHub^ ? airport.city : airport.name
                        self.multiCity.rows[index + 1].origin.subtitle = airport.code
                        self.multiCity.mode = .update(index + 1)
                        self.controller?.update(self.multiCity)
                    }
                }
                self.multiCity.mode = .update(index)
                self.controller?.update(self.multiCity)
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

        self.analyticsReporter.didOpenFlightDatePicker(with: type.rawValue)
        
        let departureDate = self.routes[safe: index]?.departureDate
        let previousDepartureDate = self.routes[safe: index - 1]?.departureDate

        // Selection available from date
        var selectionAvailableFromDate: Date?
        if self.route == .multiCity {
            selectionAvailableFromDate = index == 0 ? Date() : previousDepartureDate
        }

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
            selectionAvailableFrom: selectionAvailableFromDate ?? Date(),
            isMultipleSelectionAllowed: type != .single,
            selectedDates: selectedDates
        ) { dates in
            guard let dates else { return }
            
            let format = "E, d MMM"
            switch type {
            case .single:
                if self.routes[safe: index] != nil {
                    self.routes[index].departureDate = dates.lowerBound
                } else {
                    self.routes.append(.init(departureDate: dates.lowerBound))
                }
                switch self.route {
                case .oneWay:
                    let dateString = dates.lowerBound.string(format)
                    let model = AviaDatePickerModel(
                        title: dateString,
                        placeholder: Constants.singleDatePlaceholder
                    )
                    
                    self.analyticsReporter.didSelectFlight(date: model.title ?? "",
                                                           direction: model.placeholder)
                    self.controller?.update(model, for: .single)
                case .multiCity:
                    // Update the row at index
                    self.multiCity.rows[index].date.title = dates.lowerBound.string("d MMM")
                    self.multiCity.rows[index].date.subtitle = dates.lowerBound.string("E")
                    self.multiCity.mode = .update(index)
                    self.controller?.update(self.multiCity)

                    self.analyticsReporter.didChooseMultiCity()
                    // Check next dates for validness
                    self.validateDates(from: index + 1)
                default:
                    return
                }
            case .departure, .return:
                if self.routes[safe: index] != nil {
                    self.routes[index].departureDate = dates.lowerBound
                } else {
                    self.routes.append(.init(departureDate: dates.lowerBound))
                }

                if self.routes[safe: index + 1] != nil {
                    self.routes[index + 1].departureDate = dates.upperBound
                } else {
                    self.routes.append(.init(departureDate: dates.upperBound))
                }

                let departureDateString = dates.lowerBound.string(format)
                let returnDateString = dates.upperBound.string(format)
                let departureDateModel = AviaDatePickerModel(
                    title: departureDateString,
                    placeholder: Constants.departureDatePlaceholder
                )
                let returnDateModel = AviaDatePickerModel(
                    title: returnDateString,
                    placeholder: Constants.returnDatePlaceholder
                )
                
                self.analyticsReporter.didSelectFlight(date: returnDateModel.title ?? "",
                                                       direction: returnDateModel.placeholder)
                
                self.controller?.update(departureDateModel, for: .departure)
                self.controller?.update(returnDateModel, for: .return)
            }
        }
        
        ModalRouter(
            source: self.controller,
            destination: dateController,
            modalPresentationStyle: .formSheet
        ).route()
    }

    func flipAirports() {
        guard self.routes[safe: 0]?.departureLocation != nil,
              self.routes[safe: 0]?.arrivalLocation != nil else {
            return
        }

        let tempDepartureAiport = self.routes.first?.departureLocation
        self.routes[0].departureLocation = self.routes.first?.arrivalLocation
        self.routes[0].arrivalLocation = tempDepartureAiport

        let departure = FlightLeg.departure
        let arrival = FlightLeg.arrival

        var departureValue: String?
        var arrivalValue: String?

        if let departureAirport = self.routes[0].departureLocation {
			departureValue = [departureAirport.name, departureAirport.city].joined(", ")
        }

        if let arrivalAirport = self.routes[0].arrivalLocation {
            arrivalValue = [arrivalAirport.name, arrivalAirport.city].joined(", ")
        }

        self.controller?.update(
            .departure,
            with: .init(value: departureValue, placeholder: departure.placeholder)
        )
        self.controller?.update(
            .arrival,
            with: .init(value: arrivalValue, placeholder: arrival.placeholder)
        )

        let flipModel = AviaFlipModel(
            departure: self.routes[safe: 0]?.departureLocation?.code ?? "",
            arrival: self.routes[safe: 0]?.arrivalLocation?.code ?? ""
        )
        self.controller?.flip(with: flipModel)
    }

    // MARK: - Create task

    func createTask(completion: @escaping (Int?, Error?) -> Void) {
        guard self.areRoutesValid, self.passengers.adults > 0 else {
            completion(nil, RequestCreationError.blankFields)
            return
		}

        let routes = self.routes.map { viewModel in
            let departureLocation = viewModel.departureLocation?.isHub ?? false
            ? "\(viewModel.departureLocation?.city ?? "") \(viewModel.departureLocation?.code ?? "")"
            : viewModel.departureLocation?.name
            
            let arrivalLocation = viewModel.arrivalLocation?.isHub ?? false
            ? "\(viewModel.arrivalLocation?.city ?? "") \(viewModel.arrivalLocation?.code ?? "")"
            : viewModel.arrivalLocation?.name
            
            return Route(
                arrivalDate: viewModel.arrivalDate?.string("yyyy-MM-dd HH:mm") ?? "",
                arrivalLocation: arrivalLocation ?? "",
                departureDate: viewModel.departureDate?.string("yyyy-MM-dd HH:mm") ?? "",
                departureLocation: departureLocation ?? ""
            )
        }

        let aviaInput = AviaInput(
            adults: self.passengers.adults,
            children: self.passengers.children,
            infants: self.passengers.infants,
            serviceClass: self.passengers.isBusinessSelected ? "Бизнес" : "Эконом",
            routes: routes,
            tripType: self.route.rawValue
        )

        let aviaTaskRequest = TaskInput(
            taskTypeId: TaskTypeEnumeration.avia.id,
            avia: aviaInput
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let taskRequestJSONData = try? encoder.encode(aviaTaskRequest),
            let taskRequestJSON = String(data: taskRequestJSONData, encoding: .utf8) {
            DebugUtils.shared.log(sender: self, "\n\n aviaTaskRequest json \(taskRequestJSON)")
        }

        let variables = [
            "customerId": AnyEncodable(value: localAuthService.user?.username),
            "taskRequest": AnyEncodable(value: aviaTaskRequest)
        ]

        self.graphQLEndpoint.request(
            query: GraphQLConstants.create,
            variables: variables
        ).promise.done { [weak self] (response: CreateResponse) in
			completion(response.taskId, nil)
			DebugUtils.shared.log(sender: self, "avia task created \(response.taskId)")
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) avia request creation failed",
					parameters: error.asDictionary
				)

            completion(nil, RequestCreationError.serverResponseFailure)
            DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING AVIA TASK: \(error.localizedDescription)")
        }
    }

    func addFlight() {
        guard self.multiCity.rows.count < 10 else {
            return
        }

        let route = RouteViewModel()
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
            guard let nextDepartureDate = iterator.element.departureDate,
                  let previousDepartureDate = self.routes[iterator.offset + index - 1].departureDate,
                  nextDepartureDate < previousDepartureDate else {
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

        self.multiCity.rows[index].origin.title = departureLocation?.isHub ?? false ? departureLocation?.city : departureLocation?.name
        self.multiCity.rows[index].origin.subtitle = departureLocation?.code
        self.multiCity.rows[index].destination.title = arrivalLocation?.isHub ?? false ? arrivalLocation?.city : arrivalLocation?.name
        self.multiCity.rows[index].destination.subtitle = arrivalLocation?.code
        self.multiCity.rows[index].date.title = departureDate?.string("d MMM")
        self.multiCity.rows[index].date.subtitle = departureDate?.string("E")
        self.multiCity.mode = .update(index)
        self.controller?.update(self.multiCity)
    }
}
