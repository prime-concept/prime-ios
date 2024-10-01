@testable import Prime

final class AnalyticsReportingServiceProtocolMock {
    
    var openedModalType_invocationCount = 0
    var openedModalType_types = [TasksListType]()
    
    var tappedPayment_invocationCount = 0
    
    var expandedCalendar_invocationCount = 0
    
    var didSelectPromoCategory_invocationCount = 0
    var didSelectPromoCategory_categoryNames = [String]()
    
}

extension AnalyticsReportingServiceProtocolMock: AnalyticsReportingServiceProtocol {
    
    func newVersionLaunched(_ version: String) {
        // TODO: Implement
    }
    
    func tappedBell() {
        // TODO: Implement
    }
    
    func openedPrimeTraveller() {
        // TODO: Implement
    }
    
    func openedModal(type: TasksListType) {
        openedModalType_invocationCount += 1
        openedModalType_types.append(type)
    }
    
    func tappedPayment() {
        tappedPayment_invocationCount += 1
    }
    
    func tappedAddToWallet() {
        // TODO: Implement
    }
    
    func tappedPlusButton(_ form: AnalyticsEvents.Profile.AdditionForm) {
        // TODO: Implement
    }
    
    func expandedCalendar() {
        expandedCalendar_invocationCount += 1
    }
    
    func tappedEventInCalendar(mode: AnalyticsEvents.Calendar.Mode) {
        // TODO: Implement
    }
    
    func loggedInFirstTime() {
        // TODO: Implement
    }
    
    func newUserLoggedIn() {
        // TODO: Implement
    }
    
    func requestedSMSCode() {
        // TODO: Implement
    }
    
    func switchedToTelegramFromOnboarding() {
        // TODO: Implement
    }
    
    func launchFirstTime() {
        // TODO: Implement
    }
    
    func sessionStarted() {
        // TODO: Implement
    }
    
    func geoPermissionGranted() {
        // TODO: Implement
    }
    
    func pushPermissionGranted() {
        // TODO: Implement
    }
    
    func loggedInTwoTimesOrMore() {
        // TODO: Implement
    }
    
    func deeplinkedFromWebIntoChat() {
        // TODO: Implement
    }
    
    func requestToCreateRequestFromGeneralChat(category: String) {
        // TODO: Implement
    }
    
    func didSendChatMessage(chatID: String, contentType: String, category: String?) {
        // TODO: Implement
    }
    
    func didReceiveChatMessage(chatID: String, contentType: String, category: String?) {
        // TODO: Implement
    }
    
    func didSendNewRequestIntoGeneralChat(category: String) {
        // TODO: Implement
    }
    
    func userSegmentChanged(from oldSegment: String, to newSegment: String) {
        // TODO: Implement
    }
    
    func didTapOnMainBanner(link: String) {
        // TODO: Implement
    }
    
    func didTapOnBannerDashboard(index: Int, link: String) {
        // TODO: Implement
    }
    
    func didSelectPromoCategory(_ categoryName: String) {
        didSelectPromoCategory_invocationCount += 1
        didSelectPromoCategory_categoryNames.append(categoryName)
    }
    
    func didTapOnFeedbackOnMainScreen(taskId: Int, feedbackGuid: String) {
        // TODO: Implement
    }
    
    func didTapOnFeedbackInChat(taskId: Int, feedbackGuid: String) {
        // TODO: Implement
    }
    
    func didSelectFeedbackValue(rating: Int, value: String) {
        // TODO: Implement
    }
    
    func didSubmitFeedback(feedback: String) {
        // TODO: Implement
    }
    
    func didReceiveFeedbackCreatedSuccessfully(feedback: String) {
        // TODO: Implement
    }
    
    func aviaRequestCreated(_ taskID: Int) {
        // TODO: Implement
    }
    
    func hotelRequestCreated(_ taskID: Int) {
        // TODO: Implement
    }
    
    func restaurantRequestCreated(_ taskID: Int) {
        // TODO: Implement
    }
    
    func aviaRequestCreationSent() {
        // TODO: Implement
    }
    
    func hotelRequestCreationSent() {
        // TODO: Implement
    }
    
    func restaurantRequestCreationSent() {
        // TODO: Implement
    }
    
    func aviaRequestCreationFailed() {
        // TODO: Implement
    }
    
    func hotelRequestCreationFailed() {
        // TODO: Implement
    }
    
    func restaurantRequestCreationFailed() {
        // TODO: Implement
    }
    
    func log(event: Prime.AnalyticsEvent) {
        // TODO: Implement
    }
    
    func log(error: String, parameters: [String: Any]) {
        // TODO: Implement
    }
    
    func didTapOnFilterTopCategory() {
        // TODO: Implement
    }
    
    func didTapOnFilterHotelsCategory() {
        // TODO: Implement
    }
    
    func didTapOnFilterCitiesCategory() {
        // TODO: Implement
    }
    
    func didTapOnFilteredItemEvent(mode: AnalyticsEvents.HotelsList.FilterMode) {
        // TODO: Implement
    }
    
    func didTapOnSearchItems(with text: String) {
        // TODO: Implement
    }
    
    func didTapOnActivateSearchMode() {
        // TODO: Implement
    }
    
    func didTapOnZoomToMyLocation() {
        // TODO: Implement
    }
    
    func didSelectCityFromList(_ cityName: String) {
        // TODO: Implement
    }
    
    func didSelectMapTag(_ itemName: String) {
        // TODO: Implement
    }
    
    func didSelectFilterItemsFromAdvancedFilter(_ filterItems: String) {
        // TODO: Implement
    }
    
    func didSelectRestaurant(restaurantId: String, isFavorite: Bool) {
        // TODO: Implement
    }
    
    func didSelectRestaurantFromFilteredList() {
        // TODO: Implement
    }
    
    func didToggleFavoriteState(toFavorite: Bool, name: String) {
        // TODO: Implement
    }
    
    func didTapOnShareRestaurantDetails() {
        // TODO: Implement
    }
    
    func didOpenRestaurantWebPage() {
        // TODO: Implement
    }
    
    func didTapOnShowRouteToRestaurantLocation() {
        // TODO: Implement
    }
    
    func didExpandMapView() {
        // TODO: Implement
    }
    
    func didSelectOnRestaurantMapPin() {
        // TODO: Implement
    }
    
    func didMoveMapView() {
        // TODO: Implement
    }
    
    func didExpandRestaurantDescription() {
        // TODO: Implement
    }
    
    func didTapOnBookingButton() {
        // TODO: Implement
    }
    
    func didShowRestaurantScheduleForTodayOrTomorrow(id: String, name: String) {
        // TODO: Implement
    }
    
    func didOpenAirportListForm(leg: String) {
        // TODO: Implement
    }
    
    func didSelectAvia(route: String) {
        // TODO: Implement
    }
    
    func didSelect(airport name: String, leg: String) {
        // TODO: Implement
    }
    
    func didOpenFlightDatePicker(with type: String) {
        // TODO: Implement
    }
    
    func didSelectFlight(date: String, direction: String) {
        // TODO: Implement
    }
    
    func didChooseMultiCity() {
        // TODO: Implement
    }
    
    func didTapOpenVipLoungeForm() {
        // TODO: Implement
    }
    
    func didTapOnChooseVipLounge(date: String) {
        // TODO: Implement
    }
    
    func didSelectPassengers(count: String) {
        // TODO: Implement
    }
    
    func didSelectAirport(name: String, routе: String, cost: String?) {
        // TODO: Implement
    }
    
    func didTapOnChooseRouteType(typeName: String) {
        // TODO: Implement
    }
    
    func didCreateVipLoungeRequest(taskId: String) {
        // TODO: Implement
    }
    
}
