import Foundation
import RestaurantSDK

private protocol SendRestaurantAnalytics {
    func didSelectCityFromList(_ notification: Notification)
}

final class RestaurantSDKNotificationsHandler {
	// Оставляем shared, это безопасно, тк тут нет меняющегося стейта
    static let shared = RestaurantSDKNotificationsHandler()
    
    private let analyticsReporter: AnalyticsReportingService
    
    private init() {
        analyticsReporter = AnalyticsReportingService()
        self.registerOnRestaurantNotifications()
    }
    
    func registerOnRestaurantNotifications() {
        Notification.onReceive(.didTapOnActivateSerchMode) { [weak self] _ in
            self?.didTapOnActivateSearchMode()
        }
        
        Notification.onReceive(.didTapOnZoomToMyLocation) { [weak self] _ in
            self?.didTapOnZoomToMyLocation()
        }
        
        Notification.onReceive(.chooseCityFromList) { [weak self] notification in
            self?.didSelectCityFromList(notification)
        }
        
        Notification.onReceive(.didSelecFilterItemFromMapTag) { [weak self] notification in
            self?.didSelectMapTag(notification)
        }
        
        Notification.onReceive(.didSelectFilterItemsFromAdvancedFilter) { [weak self] notification in
            self?.didSelectFilterItemsFromAdvancedFilter(notification)
        }
        
        Notification.onReceive(.didSelectRestaurantFromFavoritesList) { [weak self] notification in
            self?.didSelectRestaurantFromFavoritesList(notification)
        }
        
        Notification.onReceive(.didSelectRestaurantFromFilteredList) { [weak self] _ in
            self?.didSelectRestaurantFromFilteredList()
        }
        
        Notification.onReceive(.didToggleFavoriteState) { [weak self] notification in
            self?.didToggleFavoriteState(notification)
        }
        
        Notification.onReceive(.didTapOnShareRestaurantDetails) { [weak self] _ in
            self?.didTapOnShareRestaurantDetails()
        }
        
        Notification.onReceive(.didOpenRestaurantWebPage) { [weak self] _ in
            self?.didOpenRestaurantWebPage()
        }
        
        Notification.onReceive(.didTapOnShowRouteToRestaurantLocation) { [weak self] _ in
            self?.didTapOnShowRouteToRestaurantLocation()
        }
        
        Notification.onReceive(.didExpandMapView) { [weak self] _ in
            self?.didExpandMapView()
        }
        
        Notification.onReceive(.didTapOnRestaurantMapPin) { [weak self] _ in
            self?.didSelectOnRestaurantMapPin()
        }
        
        Notification.onReceive(.didMoveMapView) { [weak self] _ in
            self?.didMoveMapView()
        }
        
        Notification.onReceive(.didExpandRestaurantDescription) { [weak self] _ in
            self?.didExpandRestaurantDescription()
        }
        
        Notification.onReceive(.didTapOnBookingButton) { [weak self] _ in
            self?.didTapOnBookingButton()
        }
        
        Notification.onReceive(.didShowRestaurantScheduleForTodayOrTomorrow) { [weak self] notification in
            self?.didShowRestaurantScheduleForTodayOrTomorrow(notification)
        }
    }
}

extension RestaurantSDKNotificationsHandler: SendRestaurantAnalytics {
    @objc
    fileprivate func didTapOnActivateSearchMode() {
        analyticsReporter.didTapOnActivateSearchMode()
    }
    
    @objc
    fileprivate func didTapOnZoomToMyLocation() {
        analyticsReporter.didTapOnZoomToMyLocation()
    }
    
    @objc
    fileprivate func didSelectCityFromList(_ notification: Notification) {
        if let cityName = notification.userInfo?["chosenCity"] as? String {
            analyticsReporter.didSelectCityFromList(cityName)
        }
    }
    
    @objc
    fileprivate func didSelectMapTag(_ notification: Notification) {
        if let filterItemName = notification.userInfo?["filterItemName"] as? String {
            analyticsReporter.didSelectMapTag(filterItemName)
        }
    }
    
    @objc
    fileprivate func didSelectFilterItemsFromAdvancedFilter(_ notification: Notification) {
        if let advancedFilterJsonString = notification.userInfo?["advancedFiltersJson"] as? String {
            analyticsReporter.didSelectFilterItemsFromAdvancedFilter(advancedFilterJsonString)
        }
    }
    
    @objc
    fileprivate func didSelectRestaurantFromFavoritesList(_ notification: Notification) {
        if let isFromFavorite = notification.userInfo?["isFavorite"] as? Bool,
           let restaurantId = notification.userInfo?["restaurantId"] as? String {
            analyticsReporter.didSelectRestaurant(restaurantId: restaurantId, isFavorite: isFromFavorite)
        }
    }
    
    @objc
    fileprivate func didSelectRestaurantFromFilteredList() {
        analyticsReporter.didSelectRestaurantFromFilteredList()
    }
    
    @objc
    fileprivate func didToggleFavoriteState(_ notification: Notification) {
        if let isAddedFavorite = notification.userInfo?["isFavorite"] as? Bool,
           let name = notification.userInfo?["restaurantName"] as? String {
            analyticsReporter.didToggleFavoriteState(toFavorite: isAddedFavorite, name: name)
        }
    }
    
    @objc
    fileprivate func didTapOnShareRestaurantDetails() {
        analyticsReporter.didTapOnShareRestaurantDetails()
    }
    
    @objc
    fileprivate func didOpenRestaurantWebPage() {
        analyticsReporter.didOpenRestaurantWebPage()
    }
    
    @objc
    fileprivate func didTapOnShowRouteToRestaurantLocation() {
        analyticsReporter.didTapOnShowRouteToRestaurantLocation()
    }
    
    @objc
    fileprivate func didExpandMapView() {
        analyticsReporter.didExpandMapView()
    }
    
    @objc
    fileprivate func didSelectOnRestaurantMapPin() {
        analyticsReporter.didSelectOnRestaurantMapPin()
    }
    
    @objc
    fileprivate func didMoveMapView() {
        analyticsReporter.didMoveMapView()
    }
    
    @objc
    fileprivate func didExpandRestaurantDescription() {
        analyticsReporter.didExpandRestaurantDescription()
    }
    
    @objc
    fileprivate func didTapOnBookingButton() {
        analyticsReporter.didTapOnBookingButton()
    }
    
    @objc
    fileprivate func didShowRestaurantScheduleForTodayOrTomorrow(_ notification: Notification) {
        if let restaurantId = notification.userInfo?["restaurantId"] as? String,
           let restaurantName = notification.userInfo?["restaurantName"] as? String {
            analyticsReporter.didShowRestaurantScheduleForTodayOrTomorrow(id: restaurantId, name: restaurantName)
        }
    }
}
