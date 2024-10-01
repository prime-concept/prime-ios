import Foundation

struct AnalyticsEvents {
    struct General {
        static var sessionStart = AnalyticsEvent(name: "Session start")
        static var launchFirstTime = AnalyticsEvent(name: "Launch first time")
        static func newVersionLaunched(_ version: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "New version launched",
                parameters: ["version": version]
            )
        }
    }
    
    struct Auth {
        static var requestedSMSCode = AnalyticsEvent(name: "Requested sms code")
        static var sessionStarted = AnalyticsEvent(name: "Session start")
        static var loggedIn = AnalyticsEvent(name: "Logged into the app")
        static var loggedInFirstTime = AnalyticsEvent(name: "Logged into the app for the first time")
        static var newUserLoggedIn = AnalyticsEvent(name: "New user logged in")
        
        static var launchFirstTime = AnalyticsEvent(name: "Launch first time")
        
        static func newVersionLaunched(_ version: String) -> AnalyticsEvent {
            AnalyticsEvent(name: "New version launched", parameters: ["version": version] )
        }
    }
    
    struct Home {
        static var tappedBell = AnalyticsEvent(name: "Tapped bell")
        static var openedPrimeTraveller = AnalyticsEvent(name: "Opened prime traveller")
        static var tappedPayment = AnalyticsEvent(name: "Tapped payment")
        static func didTapOnMainBanner(link: String) -> AnalyticsEvent {
			AnalyticsEvent(
				name: "Did tap on main banner",
				parameters: ["link": link]
			)
		}
        
        static func didTapOnBannerDashboard(index: Int, link: String) -> AnalyticsEvent  {
            // Sending (index + 1) because index is start from 0
            return AnalyticsEvent(name: "Did tap on \(index + 1) banner dashboard",
                                  parameters: ["link": link])
        }
        
		static func didSelectPromoCategory(categoryName: String) -> AnalyticsEvent {
			AnalyticsEvent(name: "Did select promo category", parameters: [
				"categoryName": categoryName
			])
		}
        
        static func openedModal(type: TasksListType) -> AnalyticsEvent {
            switch type {
            case .waitingForPayment:
                return AnalyticsEvent(name: "Opened pay modal")
            case .completed:
                return AnalyticsEvent(name: "Opened completed modal")
            case .all:
                return AnalyticsEvent(name: "Opened all tasks modal")
            }
        }
    }
    
    struct Feedback {
        static func didTapOnFeedbackOnMainScreen(taskId: Int, feedbackGuid: String) -> AnalyticsEvent {
            AnalyticsEvent(name: "Did Tap On Feedback On Main Screen", parameters: ["value": "taskId: \(taskId), feedbackGuid: \(feedbackGuid)"])
        }
        
        static func didTapOnFeedbackInChat(taskId: Int, feedbackGuid: String) -> AnalyticsEvent {
            AnalyticsEvent(name: "Did Tap On Feedback In Chat", parameters: ["value": "taskId: \(taskId), feedbackGuid: \(feedbackGuid)"])
        }
        
        static func didSelectFeedbackValue(rating: Int, value: String) -> AnalyticsEvent {
            AnalyticsEvent(name: "Did Select Feedback Value", parameters: ["value": "\(rating): \(value)"])
        }
        
        static func didSubmitFeedback(feedback: String) -> AnalyticsEvent {
            AnalyticsEvent(name: "Feedback submitted", parameters: ["feedback": feedback])
        }
        
        static func didReceiveFeedbackCreatedSuccessfully(feedback: String) -> AnalyticsEvent {
            AnalyticsEvent(name: "Feedback created successfully", parameters: ["feedback": feedback])
        }
    }
    
    struct Profile {
        enum AdditionForm: String {
            case cards, documents, contacts
        }
        
        static var tappedAddToWallet = AnalyticsEvent(name: "Tapped add to wallet button")
        
        static func tappedPlusButton(_ form: AdditionForm) -> AnalyticsEvent {
            AnalyticsEvent(name: "Tapped \(form.rawValue) plus button")
        }
        
        static func userSegmentChanged(from oldSegment: String, to newSegment: String) -> AnalyticsEvent {
            AnalyticsEvent(name: "User segment (level) changed", parameters: [
                "oldSegment": oldSegment, "newSegment": newSegment
            ])
        }
    }
    
    struct Calendar {
        enum Mode {
            case expanded, compact
        }
        
        static var expandedCalendar = AnalyticsEvent(name: "Expanded calendar")
        
        static func tappedEventInCalendar(mode: Mode) -> AnalyticsEvent {
            AnalyticsEvent(name: "Tapped event in calendar in \(mode) mode")
        }
    }
    
    struct Onboarding {
        static var switchedToTelegram = AnalyticsEvent(name: "Switched to telegram from onboarding")
    }
    
    struct Permissions {
        static var geoPermissionGranted = AnalyticsEvent(name: "Geo permission success")
        static var pushPermissionGranted = AnalyticsEvent(name: "Push permission success")
    }
    
    struct RequestCreation {
    
        enum CreationMode: String {
            case sent = "Sent"
            case failed = "Failed"
        }
        
        static var deeplinkedFromWebIntoChat = AnalyticsEvent(name: "Successfully deeplinked into chat from web")
        
        static func willShow(form: String) -> AnalyticsEvent  {
            AnalyticsEvent(
                name: "Will Show Form:",
                parameters: ["Form": form]
            )
        }
        
        static func requestToCreateRequestFromGeneralChat(category: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Request to create request from general chat",
                parameters: ["category": category]
            )
        }
        
        static func requestCreated(_ name: String, _ taskID: Int) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "\(name) request created successfully",
                parameters: ["taskID": taskID]
            )
        }
        
        static func requestCreation(name: String, mode: CreationMode) -> AnalyticsEvent {
            AnalyticsEvent(name: "\(name) Request Creation \(mode.rawValue)")
        }
    }
    
    struct HotelsList {
        enum FilterMode {
            case top(Int), hotels(Int), cities(Int)
        }
        
        static func didTapOnFilter(category: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "HotelsList Did Tap On Filter:",
                parameters: ["Category": category]
            )
        }
        
        static func didTapOnSearchItems(with text: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "HotelsList Will Search",
                parameters: ["text": text]
            )
        }
        
        static func didTapOnFilteredItemEvent(mode: FilterMode) -> AnalyticsEvent {
            
            var selectedItemId = ""
            
            switch mode {
            case .top(let id):
                selectedItemId = "\(id)"
            case .hotels(let id):
                selectedItemId = "\(id)"
            case .cities(let id):
                selectedItemId = "\(id)"
            }
            
            return AnalyticsEvent(
                name: "HotelsList Did Tap On Filtered Item",
                parameters: ["Item": selectedItemId]
            )
        }
    }
    struct RestaurantModule {
        static var didTapOnActivateSearchMode = AnalyticsEvent(name: "Did Tap On Activate Search Mode")
        static var didTapOnZoomToMyLocation = AnalyticsEvent(name: "Did Tap On Zoom To My Location")
        static var didSelectRestaurantFromFilteredList = AnalyticsEvent(name: "Did Select Restaurant Item From Filtered List")
        static var didTapOnShareRestaurantDetails = AnalyticsEvent(name: "Did Tap On Share Restaurant Details")
        static var didOpenRestaurantWebPage = AnalyticsEvent(name: "Did Open Restaurant Web Page")
        static var didTapOnShowRouteToRestaurantLocation = AnalyticsEvent(name: "Did Select On Show Route To Restaurant Location")
        static var didExpandMapView = AnalyticsEvent(name: "Did Expand Map View")
        static var didSelectOnRestaurantMapPin = AnalyticsEvent(name: "Did Select On Restaurant Map Pin")
        static var didMoveMapView = AnalyticsEvent(name: "Did Move Map View")
        static var didExpandRestaurantDescription = AnalyticsEvent(name: "Did Expanding Restaurant Description")
        static var didTapOnBookingButton = AnalyticsEvent(name: "Did Tap On Booking Button")
        
        static func didToggleFavoriteState(toFavorite: Bool, name: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Select On Update Favorite State:",
                parameters: ["favoriteState": toFavorite, "restaurantName": name]
            )
        }
        static func didShowRestaurantScheduleForTodayOrTomorrow(id: String, name: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Show Restaurant Schedule For Today Or Tomorrow:",
                parameters: ["restaurantId": id, "restaurantName": name]
            )
        }
        
        static func didSelectCityFromList(_ cityName: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Select City From List:",
                parameters: ["cityName": cityName]
            )
        }
        
        static func didSelectFilterItemOnMap(_ itemName: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Tap On Choose Category From Horizontal Scrolling Filter:",
                parameters: ["filterItemName": itemName]
            )
        }
        
        static func didSelectFilterItemsFromAdvancedFilter(filterItems: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did select Filter Items List with Categories From Advanced Filter:",
                parameters: ["advancedFilterItems": filterItems]
            )
        }
        
        static func didSelectRestaurant(restaurantId: String, isFavorite: Bool) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Select Restaurant Item From Favorites:",
                parameters: ["restaurantId": restaurantId, "isFavorite": isFavorite]
            )
        }
    }
    
    struct AviaModule {
        static var didChooseMultiCity = AnalyticsEvent(name: "Did Choose Multi City Direction")
        
        static func didSelectAvia(route: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Select Avia Route:",
                parameters: ["route": route]
            )
        }
        
        static func didOpenAirportListForm(leg: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Open Airport List Form:",
                parameters: ["flightLeg": leg]
            )
        }
        
        static func didSelect(airport name: String, leg: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Select Airport:",
                parameters: ["airport": name, "leg": leg]
            )
        }
        
        static func didOpenFlightDatePicker(with type: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Open Flight Date Picker:",
                parameters: ["dateType": type]
            )
        }
        
        static func didSelectFlight(date: String, direction: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Select Flight Date:",
                parameters: ["date": date, "direction": direction]
            )
        }
    }
    
    // Aeroflot: Vip Lounge Form
    struct VipLounge {
        static var didTapOpenVipLoungeForm = AnalyticsEvent(name: "Did Tap Open Vip Lounge Form")
        
        static func didTapOnChooseVipLounge(date: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Did Tap On Choose Vip Lounge:",
                parameters: ["date": date]
            )
        }
        
        static func didSelectPassengers(count: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Vip Lounge: Did Select Passengers Count:",
                parameters: ["passengersCount": count]
            )
        }
        
        static func didSelectAirport(name: String, routе: String, cost: String? = nil) -> AnalyticsEvent {
            var paramsDict = ["name": name, "routе": routе]
            
            if let cost, !cost.isEmpty {
                paramsDict["cost"] = cost
            }
            
            return AnalyticsEvent(
                name: "Vip Lounge: Did Select Airport:",
                parameters: paramsDict
            )
        }
        
        static func didTapOnChooseRouteType(typeName: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Vip Lounge: Did Tap On Choose Route Type:",
                parameters: ["typeName": typeName]
            )
        }
        
        static func didCreateVipLoungeRequest(taskId: String) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "Vip Lounge: Did Create Request:",
                parameters: ["taskId": taskId]
            )
        }
    }
    
    // Chat events
    struct Chat {
        static func didSendChatMessage(chatID: String, contentType: String, category: String?) -> AnalyticsEvent  {
            var parameters = ["chatID": chatID, "contentType": contentType]
            if let category {
                parameters["category"] = category
            }
            
            return AnalyticsEvent(
                name: "Chat: Did Send Message",
                parameters: parameters
            )
        }
        
        static func didReceiveChatMessage(chatID: String, contentType: String, category: String?) -> AnalyticsEvent  {
            var parameters = ["chatID": chatID, "contentType": contentType]
            if let category {
                parameters["category"] = category
            }
            
            return AnalyticsEvent(
                name: "Chat: Did Receive Message",
                parameters: parameters
            )
        }
        
        static func didSendNewRequestIntoGeneralChat(category: String) -> AnalyticsEvent  {
            AnalyticsEvent(
                name: "General Chat: Did Send New Request",
                parameters: ["category": category]
            )
        }
    }
}
