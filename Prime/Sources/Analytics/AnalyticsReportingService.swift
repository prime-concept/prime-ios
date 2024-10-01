import Foundation

protocol AnalyticsReportingServiceProtocol {
    func newVersionLaunched(_ version: String)
    func tappedBell()
    func openedPrimeTraveller()
    func openedModal(type: TasksListType)
    func tappedPayment()
    func tappedAddToWallet()
    func tappedPlusButton(_ form: AnalyticsEvents.Profile.AdditionForm)
    func expandedCalendar()
    func tappedEventInCalendar(mode: AnalyticsEvents.Calendar.Mode)
    func loggedInFirstTime()
	func newUserLoggedIn()
    func requestedSMSCode()
    func switchedToTelegramFromOnboarding()
    func launchFirstTime()
    func sessionStarted()
    func geoPermissionGranted()
    func pushPermissionGranted()
    func loggedInTwoTimesOrMore()
    func deeplinkedFromWebIntoChat()
    func requestToCreateRequestFromGeneralChat(category: String)

	func didSendChatMessage(chatID: String, contentType: String, category: String?)
	func didReceiveChatMessage(chatID: String, contentType: String, category: String?)
	func didSendNewRequestIntoGeneralChat(category: String)

	func userSegmentChanged(from oldSegment: String, to newSegment: String)

	func didTapOnMainBanner(link: String)
    func didTapOnBannerDashboard(index: Int, link: String)
	func didSelectPromoCategory(_ categoryName: String)

	func didTapOnFeedbackOnMainScreen(taskId: Int, feedbackGuid: String)
	func didTapOnFeedbackInChat(taskId: Int, feedbackGuid: String)
	func didSelectFeedbackValue(rating: Int, value: String)
	func didSubmitFeedback(feedback: String)
	func didReceiveFeedbackCreatedSuccessfully(feedback: String)

    func aviaRequestCreated(_ taskID: Int)
    func hotelRequestCreated(_ taskID: Int)
    func restaurantRequestCreated(_ taskID: Int)
    
    func aviaRequestCreationSent()
    func hotelRequestCreationSent()
    func restaurantRequestCreationSent()
    
    func aviaRequestCreationFailed()
    func hotelRequestCreationFailed()
    func restaurantRequestCreationFailed()
    
    func log(event: AnalyticsEvent)
    func log(error: String, parameters: [String: Any])
    
    func didTapOnFilterTopCategory()
    func didTapOnFilterHotelsCategory()
    func didTapOnFilterCitiesCategory()
    func didTapOnFilteredItemEvent(mode: AnalyticsEvents.HotelsList.FilterMode)
    func didTapOnSearchItems(with text: String)
    
    // From Restaurant Module
    func didTapOnActivateSearchMode()
    func didTapOnZoomToMyLocation()
    func didSelectCityFromList(_ cityName: String)
    func didSelectMapTag(_ itemName: String)
    func didSelectFilterItemsFromAdvancedFilter(_ filterItems: String)
    func didSelectRestaurant(restaurantId: String, isFavorite: Bool)
    func didSelectRestaurantFromFilteredList()
    func didToggleFavoriteState(toFavorite: Bool, name: String)
    func didTapOnShareRestaurantDetails()
    func didOpenRestaurantWebPage()
    func didTapOnShowRouteToRestaurantLocation()
    func didExpandMapView()
    func didSelectOnRestaurantMapPin()
    func didMoveMapView()
    func didExpandRestaurantDescription()
    func didTapOnBookingButton()
    func didShowRestaurantScheduleForTodayOrTomorrow(id: String, name: String)
    
    // From Avia Module
    func didOpenAirportListForm(leg: String)
    func didSelectAvia(route: String)
    func didSelect(airport name: String, leg: String)
    func didOpenFlightDatePicker(with type: String)
    func didSelectFlight(date: String, direction: String)
    func didChooseMultiCity()

    //Form Vip Lounge Form
    func didTapOpenVipLoungeForm()
    func didTapOnChooseVipLounge(date: String)
    func didSelectPassengers(count: String)
    func didSelectAirport(name: String, routе: String, cost: String?)
    func didTapOnChooseRouteType(typeName: String)
    func didCreateVipLoungeRequest(taskId: String)
}

final class AnalyticsReportingService: AnalyticsReportingServiceProtocol {
	// Оставляем shared, это безопасно, тк тут нет стейта
    static let shared = AnalyticsReportingService()
    
    func newVersionLaunched(_ version: String) {
        AnalyticsEvents.Auth.newVersionLaunched(version).send()
    }
    
    func tappedBell() {
        AnalyticsEvents.Home.tappedBell.send()
    }
    
    func openedPrimeTraveller() {
        AnalyticsEvents.Home.openedPrimeTraveller.send()
    }
    
    func openedModal(type: TasksListType) {
        AnalyticsEvents.Home.openedModal(type: type).send()
    }
    
    func tappedPayment() {
        AnalyticsEvents.Home.tappedPayment.send()
    }
    
    func tappedAddToWallet() {
        AnalyticsEvents.Profile.tappedAddToWallet.send()
    }
    
    func tappedPlusButton(_ form: AnalyticsEvents.Profile.AdditionForm) {
        AnalyticsEvents.Profile.tappedPlusButton(form).send()
    }
    
    func expandedCalendar() {
        AnalyticsEvents.Calendar.expandedCalendar.send()
    }
    
    func tappedEventInCalendar(mode: AnalyticsEvents.Calendar.Mode) {
        AnalyticsEvents.Calendar.tappedEventInCalendar(mode: mode).send()
    }
    
    func loggedInFirstTime() {
        AnalyticsEvents.Auth.loggedInFirstTime.send()
    }

	func newUserLoggedIn() {
		AnalyticsEvents.Auth.newUserLoggedIn.send()
	}
    
    func requestedSMSCode() {
        AnalyticsEvents.Auth.requestedSMSCode.send()
    }
    
    func switchedToTelegramFromOnboarding() {
        AnalyticsEvents.Onboarding.switchedToTelegram.send()
    }
    
    func launchFirstTime() {
        AnalyticsEvents.Auth.launchFirstTime.send()
    }
    
    func sessionStarted() {
        AnalyticsEvents.Auth.sessionStarted.send()
    }
    
    func geoPermissionGranted() {
        AnalyticsEvents.Permissions.geoPermissionGranted.send()
    }
    
    func pushPermissionGranted() {
        AnalyticsEvents.Permissions.pushPermissionGranted.send()
    }
    
    func loggedInTwoTimesOrMore() {
        AnalyticsEvents.Auth.loggedIn.send()
    }
    
    func deeplinkedFromWebIntoChat() {
        AnalyticsEvents.RequestCreation.deeplinkedFromWebIntoChat.send()
    }
    
    func willShowHotelForm() {
        AnalyticsEvents.RequestCreation.willShow(form: "Hotel").send()
    }
    
    func willShowAviaForm() {
        AnalyticsEvents.RequestCreation.willShow(form: "Avia").send()
    }
    
    func willShowRestaurantsForm() {
        AnalyticsEvents.RequestCreation.willShow(form: "Restaurant").send()
    }

	func didTapOnMainBanner(link: String) {
		AnalyticsEvents.Home.didTapOnMainBanner(link: link).send()
	}
    
    func didTapOnBannerDashboard(index: Int, link: String) {
        AnalyticsEvents.Home.didTapOnBannerDashboard(index: index, link: link).send()
    }

	func didTapOnFeedbackOnMainScreen(taskId: Int, feedbackGuid: String) {
		AnalyticsEvents.Feedback.didTapOnFeedbackOnMainScreen(taskId: taskId, feedbackGuid: feedbackGuid).send()
	}

	func didTapOnFeedbackInChat(taskId: Int, feedbackGuid: String) {
		AnalyticsEvents.Feedback.didTapOnFeedbackInChat(taskId: taskId, feedbackGuid: feedbackGuid).send()
	}

	func didSelectFeedbackValue(rating: Int, value: String) {
		AnalyticsEvents.Feedback.didSelectFeedbackValue(rating: rating, value: value).send()
	}

	func didSubmitFeedback(feedback: String) {
		AnalyticsEvents.Feedback.didSubmitFeedback(feedback: feedback).send()
	}

	func didReceiveFeedbackCreatedSuccessfully(feedback: String) {
		AnalyticsEvents.Feedback.didReceiveFeedbackCreatedSuccessfully(feedback: feedback).send()
	}

	func didSelectPromoCategory(_ categoryName: String) {
		AnalyticsEvents.Home.didSelectPromoCategory(categoryName: categoryName).send()
	}
    
    func requestToCreateRequestFromGeneralChat(category: String) {
        AnalyticsEvents.RequestCreation.requestToCreateRequestFromGeneralChat(category: category).send()
    }
    
    func aviaRequestCreated(_ taskID: Int) {
        AnalyticsEvents.RequestCreation.requestCreated("Avia", taskID).send()
    }
    
    func hotelRequestCreated(_ taskID: Int) {
        AnalyticsEvents.RequestCreation.requestCreated("Hotel", taskID).send()
    }
    
    func restaurantRequestCreated(_ taskID: Int) {
        AnalyticsEvents.RequestCreation.requestCreated("Restaurant", taskID).send()
    }
    
    func aviaRequestCreationSent() {
        AnalyticsEvents.RequestCreation.requestCreation(name: "Avia", mode: .sent).send()
    }
    
    func hotelRequestCreationSent() {
        AnalyticsEvents.RequestCreation.requestCreation(name: "Hotel", mode: .sent).send()
    }
    
    func restaurantRequestCreationSent() {
        AnalyticsEvents.RequestCreation.requestCreation(name: "Restaurant", mode: .sent).send()
    }
    
    func aviaRequestCreationFailed() {
        AnalyticsEvents.RequestCreation.requestCreation(name: "Avia", mode: .failed).send()
    }
    
    func hotelRequestCreationFailed() {
        AnalyticsEvents.RequestCreation.requestCreation(name: "Hotel", mode: .failed).send()
    }
    
    func restaurantRequestCreationFailed() {
        AnalyticsEvents.RequestCreation.requestCreation(name: "Restaurant", mode: .failed).send()
    }
    
    func log(event: AnalyticsEvent) {
        event.send()
    }
    
    func log(error: String, parameters: [String: Any] = [:]) {
        let string = parameters.asErrorString
        
        self.log(event: AnalyticsEvent(name: error, parameters: ["details": string]))
    }
    
    func log(name: String, parameters: [String: Any] = [:]) {
        self.log(event: AnalyticsEvent(name: name, parameters: parameters))
    }
    
    func didTapOnFilterTopCategory() {
        AnalyticsEvents.HotelsList.didTapOnFilter(category: "Top").send()
    }
    
    func didTapOnFilterHotelsCategory() {
        AnalyticsEvents.HotelsList.didTapOnFilter(category: "Hotels").send()
    }
    
    func didTapOnFilterCitiesCategory() {
        AnalyticsEvents.HotelsList.didTapOnFilter(category: "Cities").send()
    }
    
    func didTapOnFilteredItemEvent(mode: AnalyticsEvents.HotelsList.FilterMode) {
        AnalyticsEvents.HotelsList.didTapOnFilteredItemEvent(mode: mode).send()
    }
    
    func didTapOnSearchItems(with text: String) {
        AnalyticsEvents.HotelsList.didTapOnSearchItems(with: text).send()
    }
    
    // From Restaurant Module
    func didTapOnActivateSearchMode() {
        AnalyticsEvents.RestaurantModule.didTapOnActivateSearchMode.send()
    }
    
    func didTapOnZoomToMyLocation() {
        AnalyticsEvents.RestaurantModule.didTapOnZoomToMyLocation.send()
    }
    
    func didSelectCityFromList(_ cityName: String) {
        AnalyticsEvents.RestaurantModule.didSelectCityFromList(cityName).send()
    }
    
    func didSelectMapTag(_ itemName: String) {
        AnalyticsEvents.RestaurantModule.didSelectFilterItemOnMap(itemName).send()
    }
    
    func didSelectFilterItemsFromAdvancedFilter(_ filterItems: String) {
        AnalyticsEvents.RestaurantModule.didSelectFilterItemsFromAdvancedFilter(filterItems: filterItems).send()
    }
    
    func didSelectRestaurant(restaurantId: String, isFavorite: Bool) {
        AnalyticsEvents.RestaurantModule.didSelectRestaurant(restaurantId: restaurantId, isFavorite: isFavorite).send()
    }
    
    func didSelectRestaurantFromFilteredList() {
        AnalyticsEvents.RestaurantModule.didSelectRestaurantFromFilteredList.send()
    }
    
    func didToggleFavoriteState(toFavorite: Bool, name: String) {
        AnalyticsEvents.RestaurantModule.didToggleFavoriteState(toFavorite: toFavorite, name: name).send()
    }
    
    func didTapOnShareRestaurantDetails() {
        AnalyticsEvents.RestaurantModule.didTapOnShareRestaurantDetails.send()
    }
    
    func didOpenRestaurantWebPage() {
        AnalyticsEvents.RestaurantModule.didOpenRestaurantWebPage.send()
    }
    
    func didTapOnShowRouteToRestaurantLocation() {
        AnalyticsEvents.RestaurantModule.didTapOnShowRouteToRestaurantLocation.send()
    }
    func didExpandMapView() {
        AnalyticsEvents.RestaurantModule.didExpandMapView.send()
    }
    
    func didSelectOnRestaurantMapPin() {
        AnalyticsEvents.RestaurantModule.didSelectOnRestaurantMapPin.send()
    }
    
    func didMoveMapView() {
        AnalyticsEvents.RestaurantModule.didMoveMapView.send()
    }
    
    func didExpandRestaurantDescription() {
        AnalyticsEvents.RestaurantModule.didExpandRestaurantDescription.send()
    }
    
    func didTapOnBookingButton() {
        AnalyticsEvents.RestaurantModule.didTapOnBookingButton.send()
    }
    
    func didShowRestaurantScheduleForTodayOrTomorrow(id: String, name: String) {
        AnalyticsEvents.RestaurantModule.didShowRestaurantScheduleForTodayOrTomorrow(id: id, name: name).send()
    }
    
    // From Avia Module
    func didOpenAirportListForm(leg: String) {
        AnalyticsEvents.AviaModule.didOpenAirportListForm(leg: leg).send()
    }
    
    func didSelectAvia(route: String) {
        AnalyticsEvents.AviaModule.didSelectAvia(route: route).send()
    }
    
    func didSelect(airport name: String, leg: String) {
        AnalyticsEvents.AviaModule.didSelect(airport: name, leg: leg).send()
    }
    
    func didOpenFlightDatePicker(with type: String) {
        AnalyticsEvents.AviaModule.didOpenFlightDatePicker(with: type).send()
    }
    
    func didSelectFlight(date: String, direction: String) {
        AnalyticsEvents.AviaModule.didSelectFlight(date: date, direction: direction).send()
    }
    
    func didChooseMultiCity() {
        AnalyticsEvents.AviaModule.didChooseMultiCity.send()
    }

    // Vip Lounge Form
    func didTapOpenVipLoungeForm() {
        AnalyticsEvents.VipLounge.didTapOpenVipLoungeForm.send()
    }
    
    func didTapOnChooseVipLounge(date: String) {
        AnalyticsEvents.VipLounge.didTapOnChooseVipLounge(date: date).send()
    }
    
    func didSelectPassengers(count: String) {
        AnalyticsEvents.VipLounge.didSelectPassengers(count: count).send()
    }
    
    func didSelectAirport(name: String, routе: String, cost: String? = nil) {
        AnalyticsEvents.VipLounge.didSelectAirport(name: name, routе: routе, cost: cost).send()
    }
    
    func didTapOnChooseRouteType(typeName: String) {
        AnalyticsEvents.VipLounge.didTapOnChooseRouteType(typeName: typeName).send()
    }
    
    func didCreateVipLoungeRequest(taskId: String) {
        AnalyticsEvents.VipLounge.didCreateVipLoungeRequest(taskId: taskId).send()
    }
    
    // Chat form
	func didSendChatMessage(chatID: String, contentType: String, category: String?) {
		AnalyticsEvents.Chat.didSendChatMessage(chatID: chatID, contentType: contentType, category: category).send()
	}

	func didReceiveChatMessage(chatID: String, contentType: String, category: String?) {
		AnalyticsEvents.Chat.didReceiveChatMessage(chatID: chatID, contentType: contentType, category: category).send()
	}

	func didSendNewRequestIntoGeneralChat(category: String) {
		AnalyticsEvents.Chat.didSendNewRequestIntoGeneralChat(category: category).send()
	}

	func userSegmentChanged(from oldSegment: String, to newSegment: String) {
		AnalyticsEvents.Profile.userSegmentChanged(from: oldSegment, to: newSegment).send()
	}
}

fileprivate extension Dictionary where Key == String {
    var asErrorString: String {
        var string = ""
        
        if let type = self["type"] {
            string.append("TYPE: \(type)\n")
        }
        if let code = self["code"] {
            string.append("CODE: \(code)\n")
        }
        if let curl = self["curl"] {
            string.append("CURL:\n\(curl)\n\n")
        }
        if let response = self["response"] {
            string.append("RESPONSE:\n\(response)\n\n")
        }
        if let details = self["details"] {
            string.append("DETAILS:\n\(details)\n")
        }
        
        let standardKeys = ["type", "code", "curl", "response", "details"]
        
        var keys = Array(self.keys)
        keys = keys.skip{ standardKeys.contains($0) }
        keys.forEach { key in
            if let value = self[key] {
                string.append("\(key.uppercased()):\n\(value)\n")
            }
        }
        
        return string
    }
}
