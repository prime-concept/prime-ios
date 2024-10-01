import Foundation

protocol HotelFormPresenterProtocol: AnyObject {
    func didLoad()

    func selectPlaceOfResidence()
    func selectDates()
    func openGuestsSelection()

    func createTask(completion: @escaping (Int?, Error?) -> Void)
}

final class HotelFormPresenter: HotelFormPresenterProtocol {
    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let localAuthService: LocalAuthServiceProtocol

    weak var controller: HotelFormViewControllerProtocol?

    private var hotel: Hotel?
    private var hotelCity: HotelCity?
    private var guests: HotelGuests = .default
    private var checkInDate = Date() + 1.days
    private var checkOutDate = Date() + 4.days

    private var isValidForm: Bool {
        guard self.hotel != nil || self.hotelCity != nil,
              self.guests.adults > 0
        else {
            return false
        }
        return true
    }

    init(
        graphQLEndpoint: GraphQLEndpointProtocol,
        localAuthService: LocalAuthServiceProtocol
    ) {
        self.graphQLEndpoint = graphQLEndpoint
        self.localAuthService = localAuthService
    }

    func didLoad() {
        let hotelViewModel = HotelFormRowViewModel(field: .hotel)
        let guestsViewModel = HotelFormRowViewModel(
            field: .guests,
            value: String(self.guests.total),
            isSeparatorHidden: true
        )

        self.controller?.setupPlaceOfResidence(hotelViewModel)
        self.controller?.setupGuests(guestsViewModel)
        self.set(checkIn: self.checkInDate, checkOut: self.checkOutDate)
    }

    func selectPlaceOfResidence() {
        Notification.post(.messageInputShouldHideKeyboard)

        let assembly = HotelsListAssembly { [weak self] hotel, city in
            guard let self = self else {
                return
            }
            self.hotel = hotel
            self.hotelCity = city
            let hotelViewModel = HotelFormRowViewModel(
                field: .hotel,
                value: hotel?.name ?? city?.name ?? "",
                isSeparatorHidden: false
            )
            self.controller?.setupPlaceOfResidence(hotelViewModel)
        }
        let hotelsController = assembly.make()
        ModalRouter(
            source: self.controller,
            destination: hotelsController,
            modalPresentationStyle: .pageSheet
        ).route()
    }

    func selectDates() {
        Notification.post(.messageInputShouldHideKeyboard)

        let checkInDate = self.checkInDate.down(to: .day)
        let checkOutDate = self.checkOutDate.down(to: .day)
        let selectedDates = checkInDate...checkOutDate

        let dateController = FSCalendarRangeSelectionViewController(
            monthCount: 12,
            selectedDates: selectedDates
        ) { dates in
            guard let dates = dates else {
                return
            }
            self.set(checkIn: dates.lowerBound, checkOut: dates.upperBound)
        }
        ModalRouter(
            source: self.controller,
            destination: dateController,
            modalPresentationStyle: .pageSheet
        ).route()
    }

    func openGuestsSelection() {
        Notification.post(.messageInputShouldHideKeyboard)

        let assembly = HotelGuestsAssembly(guests: self.guests) { [weak self] guests in
            guard let self = self else {
                return
            }
            self.guests = guests
            let guestsViewModel = HotelFormRowViewModel(
                field: .guests,
                value: String(guests.total),
                isSeparatorHidden: true
            )
            self.controller?.setupGuests(guestsViewModel)
        }
        let guestsController = assembly.make()
        ModalRouter(
            source: self.controller,
            destination: guestsController,
            modalPresentationStyle: .formSheet
        ).route()
    }

    func createTask(completion: @escaping (Int?, Error?) -> Void) {
        guard self.isValidForm else {
            completion(nil, RequestCreationError.blankFields)
            return
        }

        var kidsBirthdays: String = ""
        self.guests.children.ages.enumerated().forEach { iterator in
            guard iterator.offset != self.guests.children.ages.endIndex - 1 else {
                kidsBirthdays.append("\(iterator.element)")
                return
            }
            kidsBirthdays.append("\(iterator.element), ")
        }
        let hotelInput = HotelInput(
            adultsCount: self.guests.adults,
            childCount: self.guests.children.amount,
            checkInDate: self.checkInDate.string("yyyy-MM-dd HH:mm"),
            checkOutDate: self.checkOutDate.string("yyyy-MM-dd HH:mm"),
            city: self.hotelCity?.name,
            country: self.hotelCity?.country?.name,
            hotelId: self.hotel?.id,
            hotelName: self.hotel?.name,
            kidsBirthdays: kidsBirthdays,
            numOfRooms: String(self.guests.rooms)
        )

        let hotelTaskRequest = TaskInput(
            taskTypeId: TaskTypeEnumeration.hotel.id,
            hotel: hotelInput
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let taskRequestJSONData = try? encoder.encode(hotelTaskRequest),
            let taskRequestJSON = String(data: taskRequestJSONData, encoding: .utf8) {
            DebugUtils.shared.log(sender: self, "\n\n hotelTaskRequest json \(taskRequestJSON)")
        }

        let variables = [
            "customerId": AnyEncodable(value: self.localAuthService.user?.username),
            "taskRequest": AnyEncodable(value: hotelTaskRequest)
        ]
        AnalyticsReportingService.shared.hotelRequestCreationSent()
        self.graphQLEndpoint.request(
            query: GraphQLConstants.create,
            variables: variables
        ).promise.done { [weak self] (response: CreateResponse) in
			completion(response.taskId, nil)
			DebugUtils.shared.log(sender: self, "hotel task created \(response.taskId)")
        }.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) hotels task creation failed",
					parameters: error.asDictionary
				)
            completion(nil, RequestCreationError.serverResponseFailure)
            DebugUtils.shared.alert(sender: self, "ERROR WHILE CREATING HOTEL TASK: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func set(checkIn: Date, checkOut: Date) {
        let format = "E, d MMM"

        let checkInDate = checkIn.string(format)
        self.checkInDate = checkIn

        let checkOutDate = checkOut.string(format)
        self.checkOutDate = checkOut

        let datesToShow = checkInDate + " - " + checkOutDate
        self.controller?.setupDates(
            HotelFormRowViewModel(
                field: .dates,
                value: datesToShow,
                isSeparatorHidden: true
            )
        )
    }
}
