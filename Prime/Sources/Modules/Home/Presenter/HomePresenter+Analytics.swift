extension HomePresenter {
    
    func trackChatError(_ notification: Notification) {
        self.trackError(notification, tag: "CHAT_SDK")
    }
    
    func trackRestaurantError(_ notification: Notification) {
        self.trackError(notification, tag: "RESTAURANT_SDK")
    }
    
    private func trackError(_ notification: Notification, tag: String) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
        let endpointError = Endpoint.Error(dictionary: userInfo)
        
        AnalyticsReportingService
            .shared.log(
                name: "[ERROR][\(tag)] \(userInfo["sender"] ?? "")",
                parameters: endpointError.asDictionary
            )
    }
}
