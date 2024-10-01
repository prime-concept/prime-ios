// swiftlint:disable file_length

import ChatSDK
import EventKit
import Foundation
import PromiseKit
import RestaurantSDK

extension Notification.Name {
	static let didUpdateHomeViewModel = Notification.Name("didUpdateHomeViewModel")
}

final class HomePresenter: HomePresenterProtocol {
	private enum Constants {
		static let eventsFileName = "Home-Events"
		static let taskIDsWaitingToLoadEventsName = "Home-taskIDsWaitingToLoadEvents"
		static let bannersFileName = "Home-Banners"
		static let unreadInfoFileName = "Home-UnreadInfo"
		static let taskIDsWithFailedFiles = "Home-taskIDsWithFailedFiles"
		static let fileUIDsToReloadContents = "Home-fileUIDsToReloadContents"
        static let promoCategories = "Home-PromoCategories"
		static let taskIDsToFileLists = "Home-taskIDsToFileLists"
		static let aerotickets = "Home-aerotickets"
	}

    weak var controller: HomeViewControllerProtocol?
    private weak var router: HomeRouterProtocol?
    
	private var profileTabsViewController = ProfileTabsViewController(shouldPrefetchProfile: true)

	private var pendingChatEditingEvents = [ChatEditingEvent]()
	@ThreadSafe private var pendingTaskOpeningDeeplink: (Int, () -> Void)?
	@ThreadSafe private var pendingFeedbackOpeningDeeplink: (String, (ActiveFeedback) -> Void)?

    private let taskManager: any HomeTaskManagerProtocol
    private let feedbackManager: any HomeFeedbackManagerProtocol
    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let taskPersistenceService: TaskPersistenceServiceProtocol
    private let localAuthService: LocalAuthServiceProtocol
    private let calendarService: CalendarEventsServiceProtocol
	private let profileService: ProfileServiceProtocol
    private let deeplinkService: DeeplinkService
    private let analyticsReporter: AnalyticsReportingServiceProtocol
	private let eventsEndpoint: EventsEndpoint
    private let filesService: FilesServiceProtocol
	private let servicesEndpoint: ServicesEndpointProtocol

	private var mayShowBanners = false
	@ThreadSafe private var pendingFetches = [TasksFetchDirection: (() -> Void)?]()

	@ThreadSafe private var didLoadInitialTasks = false
	@ThreadSafe private var mayRefreshRequestsList = false

	@ThreadSafe private var events = [CalendarEvent]()

	@PersistentCodable(fileName: Constants.taskIDsWaitingToLoadEventsName)
	private var taskIDsWaitingToLoadEvents: Set<Int> = []

	private var taskIDsCurrentlyBeingPolledForEvents: Set<Int> = []

	@ThreadSafe private var reportedMessageGUIDs = Set<String>()
    
    @PersistentCodable(fileName: Constants.promoCategories, async: false)
    private var promoCategories: [Int: [Int]] = [:]

	private lazy var bannerViewModels = [HomeBannerViewModel]()

	@PersistentCodable(fileName: Constants.bannersFileName)
	private var banners = [Banner]() {
		didSet {
			self.populateBannerViewModels()
		}
	}

	@PersistentCodable(fileName: Constants.unreadInfoFileName)
	private var unreadInfo = [ChatSDK.MiscClient.UnreadInfo]()

	private var limit: Int {
		UserDefaults[int: "TASKS_BATCH_COUNT"]
	}

    @ThreadSafe
	private var chatBroadcastListener: ChatBroadcastListener?

	@PersistentCodable(fileName: Constants.taskIDsWithFailedFiles, async: false)
	private var taskIDsToReloadFileLists = Set<Int>()

	@PersistentCodable(fileName: Constants.fileUIDsToReloadContents, async: false)
	private var fileUIDsToReloadContents = Set<String>()

	private func reloadFailedFileListsIfNeeded() {
		self.fetchListsOfFiles(for: self.taskIDsToReloadFileLists)
	}

	@PersistentCodable(fileName: Constants.taskIDsToFileLists, async: false)
	private var taskIDsToFileLists = [Int: [FilesResponse.File]]()

	@PersistentCodable(fileName: Constants.aerotickets, async: false)
	private var aerotickets = Aerotickets(result: [])

	private var _chatMiscClient: ChatSDK.MiscClient?
	private var chatMiscClient: ChatSDK.MiscClient {
		if let client = _chatMiscClient {
			return client
		}

		let authState = AuthState(
			accessToken: self.localAuthService.token?.accessToken,
			clientAppID: Config.chatClientAppID,
			deviceID: nil,
			wsUniqueID: nil
		)

		let client = ChatSDK.MiscClient(baseURL: Config.chatBaseURL, authState: authState)
		_chatMiscClient = client

		return client
	}

	private static let persistenseQueue = DispatchQueue(label: "HomePresenter.persistenseQueue")
	private static let tasksNetworkingQueue = DispatchQueue(label: "HomePresenter.tasksNetworkingQueue")
	private static let eventsNetworkingQueue = DispatchQueue(label: "HomePresenter.eventsNetworkingQueue")
	private static let viewModelQueue = DispatchQueue(label: "HomePresenter.viewModelQueue")
	private static let channelQueue = DispatchQueue(label: "HomePresenter.channelQueue")
    
    private var tasksRetryDelay: TimeInterval = 0
    private var channelsRetryDelay: TimeInterval = 0
    private var mayRetryRequests = true

	private var postFetchCompletionsByTasks = [Int: () -> Void]()
	private var onDidLoad: ((UIViewController) -> Void)?

	private weak var cityGuideViewController: PrimeTravellerWebViewController?

	private lazy var onMaybeAppearThrottler = Throttler(timeout: 1) { [weak self] in
		self?.reloadAllContent()
	}

    init(
        controller: HomeViewControllerProtocol,
        router: HomeRouterProtocol,
        taskManager: any HomeTaskManagerProtocol,
        feedbackManager: any HomeFeedbackManagerProtocol,
        graphQLEndpoint: GraphQLEndpointProtocol,
        taskPersistenceService: TaskPersistenceServiceProtocol,
        localAuthService: LocalAuthServiceProtocol,
        calendarService: CalendarEventsServiceProtocol,
		profileService: ProfileServiceProtocol,
        deeplinkService: DeeplinkService,
        analyticsRepoter: AnalyticsReportingServiceProtocol,
        fileService: FilesServiceProtocol,
		servicesEndpoint: ServicesEndpointProtocol,
		onDidLoad: @escaping ((UIViewController) -> Void)
    ) {
        self.controller = controller
        self.router = router
        self.taskManager = taskManager
        self.feedbackManager = feedbackManager
        self.graphQLEndpoint = graphQLEndpoint
        self.taskPersistenceService = taskPersistenceService
        self.localAuthService = localAuthService
        self.calendarService = calendarService
		self.profileService = profileService
        self.deeplinkService = deeplinkService
        self.analyticsReporter = analyticsRepoter
		self.eventsEndpoint = EventsEndpoint(authService: localAuthService)
		self.servicesEndpoint = servicesEndpoint
		self.onDidLoad = onDidLoad
        self.filesService = fileService

		self.subscribeToNotifications()
	}

	func didLoad() {
		self.configureChat()

		self.handleFirstLaunch()

		self.loadBannersIfNeeded()
		self.loadActiveFeedbacks()

		self.loadServices()

		self.loadTaskTypes {
			self.callPostFetchCompletionsByTasks()

			self.reloadUI(
				fetchTasksDB: true,
				didSetupViewModel: self.didSetupViewModel,
				completion: {
					self.loadCrossSales()
					self.loadAerotickets()

					self.loadUnreadCount { [weak self] in
						guard let self else { return }

						self.reloadUI(
							fetchTasksDB: true,
							didSetupViewModel: self.didSetupViewModel,
							completion: self.getProfileThenFetchTasks
						)
					}
                    
				}
			)
		}
	}

	private func handleFirstLaunch() {
		if UserDefaults[bool: "HAS_SHOWN_HOME_SCREEN_PREVIOUSLY"] {
			return
		}

		self.updateViewController(didSetupViewModel: self.didSetupViewModel)

		UserDefaults[bool: "HAS_SHOWN_HOME_SCREEN_PREVIOUSLY"] = true
	}

	private func populateBannerViewModels() {
		let ids = self.banners.map(\.id)
		var groupedBanners = Dictionary(grouping: banners, by: \.category)
		var orderedBanners = [[Banner]]()

		for id in ids {
			var _key: String?
			let group = groupedBanners.first { key, banners in
				if banners.contains(where: { $0.id.contains(id) }) {
					_key = key
					return true
				}
				return false
			}

			if let group {
				orderedBanners.append(group.value)
				if let _key {
					groupedBanners.removeValue(forKey: _key)
				}
			}
		}

		let viewModels = orderedBanners.flatMap { group in
			let triplets = group.split(by: 3)
			let models = triplets.map { triplet in
				HomeBannerViewModel(
					banners: triplet.map { banner in
						HomeBannerViewModel.Banner(
							id: banner.id,
							imageURL: banner.images.first?.image,
							link: banner.link
                        ) { [weak self] index in
							self?.openBanner(link: banner.link, index: index)
						}
					}
				)
			}

			return models
		}

		self.loadBannerImages(for: viewModels) { [weak self] in
			self?.bannerViewModels = viewModels
			self?.updateViewController()
		}
	}

	private func loadBannerImages(for viewModels: [HomeBannerViewModel], competion: (() -> Void)?) {
		let dispatchGroup = DispatchGroup()

		viewModels.forEach { viewModel in
			viewModel.banners.forEach { banner in
				guard let urlString = banner.imageURL, let url = URL(string: urlString) else {
					return
				}
				dispatchGroup.enter()
				UIImage.load(from: url) { image in
					banner.image = image
					dispatchGroup.leave()
				}
			}
		}

		dispatchGroup.notify(queue: .main) {
			competion?()
		}
	}

	private func loadActiveFeedbacks() {
		FeedbackEndpoint.shared.retrieveActive().promise.done { [weak self] result in
			guard let self else { return }
            feedbackManager.replaceAllFeedbacks(with: result.filter { $0.showOnTask == true })
			servePendingFeedbackOpeningDeeplink()
		}.catch { _ in
			DebugUtils.shared.log("FEEDBACKS LOADING FAILED")
		}
	}

	private func configureChat() {
		ChatSDK.Configuration.sharingGroupName = Config.sharingGroupName
		ChatSDK.MAY_LOG_IN_PRINT = Config.isDebugEnabled
		ChatSDK.acceptExternalLogger(DebugUtils.shared)
		ChatSDK.Configuration.urlOpeningHandler = { [weak self] url in
			self?.openChatURL(url) ?? false
		}
		ChatSDK.Configuration.showLoadingIndicator = {
			$0?.showLoadingIndicator(
				isUserInteractionEnabled: true,
				dismissesOnTap: true,
				needsPad: true
			)
		}
		ChatSDK.Configuration.hideLoadingIndicator = {
			$0?.hideLoadingIndicator()
		}
	}

	private func didSetupViewModel() {
		self.controller.some { self.onDidLoad?($0) }
		self.onDidLoad = nil
        mayShowBanners = taskManager.hasTasks(in: .displayable)
	}

	private func hideLoaderIfNeeded() {
        guard taskManager.hasTasks(in: .displayable) else { return }

		delay(0.3) { self.controller?.hideTasksLoader() }
	}

	private func getProfileThenFetchTasks() {
		self.profileService.getProfile(cached: false) { [weak self] profile in
			guard let self else { return }

			ChatSDK.Configuration.phoneNumberToSendSMSIfNoInternet = profile?.clubPhone

			self.hideLoaderIfNeeded()
			self.fetchTasksOnceReceived(profile: profile)
		}
	}

	private func fetchTasksOnceReceived(profile: Profile?) {
		self.fetchTasks(direction: .older) { _ in
			self.didLoadInitialTasks = true
			self.mayRefreshRequestsList = true
			self.chatBroadcastListener?.failNonSentMessages()

			self.fetchTasks(direction: .newer)
		}
	}

	private func loadServices() {
		self.servicesEndpoint.getServices()
			.promise
			.done { _ in }
			.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getServices failed",
						parameters: error.asDictionary
					)
			}
	}

	private func loadUnreadCount(reloadUI: Bool = false, completion: (() -> Void)? = nil) {
		onMain {
			var totalCount = UIApplication.shared.applicationIconBadgeNumber

			DispatchQueue.global().async { [weak self] in
				guard let self else { return }

				let group = DispatchGroup()

				group.enter()
				self.loadTotalUnreadCount { count in
					totalCount = count
					group.leave()
				}

				group.enter()
				self.loadUnreadCountsPerChats {
					group.leave()
				}

                group.notify(queue: Self.persistenseQueue) { [weak self] in
					guard let self else { return }

                    DispatchQueue.main.async {
                        UIApplication.shared.applicationIconBadgeNumber = totalCount
                    }

					let updatedTasks = self.mergeTasksUnreadInfo()
					self.saveTasks(updatedTasks) { [weak self] _ in
						if reloadUI {
							self?.reloadUI()
						}
						completion?()
					}
				}
			}
		}
	}

	private func loadTotalUnreadCount(completion: ((Int) -> Void)? = nil) {
		_ = try? self.chatMiscClient.retrieveTotalUnreadCount { result in
			onMain {
				let oldResult = UIApplication.shared.applicationIconBadgeNumber
				let result = result ?? oldResult
				DebugUtils.shared.log(sender: self, "WILL SET UNREAD COUNT PUSH ICON BADGE \(result)")
				completion?(result)
			}
		}
	}

	private func loadUnreadCountsPerChats(completion: (() -> Void)? = nil) {
		_ = try? self.chatMiscClient.retrieveUnreadCountsPerChats { result in
			onMain {
				self.unreadInfo = result ?? self.unreadInfo
				completion?()
			}
		}
	}

	private func loadBannersIfNeeded() {
		guard UserDefaults[bool: "bannersEnabled"] else {
			self.banners = []
			self.bannerViewModels = []
			return
		}

		BannerEndpoint.shared.retrieve().promise.map(\.items).done { [weak self] banners in
			self?.banners = banners
		}.catch { error in
			print("")
		}
	}

	private func loadTaskTypes(_ firstTimeCompletion: (() -> (Void))? = nil) {
		var firstTimeCompletion = firstTimeCompletion

		Self.persistenseQueue.async {
			TaskType.initCache()

			if TaskType.hasCacheForCurrentLocale {
				firstTimeCompletion?()
				firstTimeCompletion = nil
			}

			let language = Locale.primeLanguageCode

			Self.tasksNetworkingQueue.promise {
				self.graphQLEndpoint.request(
					query: GraphQLConstants.taskTypes,
					variables: [
						"lang": AnyEncodable(value: language),
						"clientId": AnyEncodable(value: Config.clientID)
					]
				).promise
			}.done(on: Self.persistenseQueue) { (taskTypes: TaskTypeResponse) in
				TaskType.updateCache(language, taskTypes.items)
				TaskType.updateTaskTypesRows(taskTypes.items)
			}.ensure {
				firstTimeCompletion?()
			}.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) KEYBOARD ROWS TaskType-s loading failed",
						parameters: error.asDictionary.appending("lang", language)
					)
				DebugUtils.shared.log("FAILED TO LOAD KEYBOARD ROWS TASK TYPES FOR LANG: \(language), ERROR:\n\(error)")
			}
		}
	}

	private func fetchCalendarEvents(for tasks: [Task], completion: (() -> Void)? = nil) {
		if tasks.isEmpty {
			completion?()
			return
		}
		
		let taskIDs = Set(tasks.map(\.taskID))
		let newTaskIDs = taskIDs.subtracting(self.taskIDsCurrentlyBeingPolledForEvents)
		if newTaskIDs.isEmpty {
			completion?()
			return
		}

		self.taskIDsWaitingToLoadEvents.formUnion(taskIDs)
		self.taskIDsCurrentlyBeingPolledForEvents.formUnion(taskIDs)

		DebugUtils.shared.log(sender: self, "REST EVENTS REQUESTED FOR \(taskIDs)")

		self.eventsEndpoint.getEventsFor(taskIds: Array(taskIDs)).promise
			.done { response in
				let events = response.data
				self.taskIDsCurrentlyBeingPolledForEvents.subtract(taskIDs)

				DebugUtils.shared.alert(sender: self, "\(events.count) REST EVENTS WILL BE DISPLAYED FOR \(taskIDs)")

				if events.isEmpty {
					self.taskIDsWaitingToLoadEvents.subtract(taskIDs)
					completion?()
					return
				}

				let (updatedTasks, removedEvents, existingEvents) = self.fillTasksWithEvents(tasks, events)

				self.saveTasks(updatedTasks, enforceEvents: false) { [weak self] _ in
					self?.calendarService.remove(events: removedEvents) {
						self?.calendarService.save(events: existingEvents) {
							onMain {
								self?.taskIDsWaitingToLoadEvents.subtract(taskIDs)
								completion?()
							}
						}
					}

					self?.reloadUI()
				}
			}.catch { error in
				let message = "[ERROR] \(Swift.type(of: self)) REST Calendar events fetch FAILED FOR \(taskIDs)"
				AnalyticsReportingService.shared.log(name: message, parameters: error.asDictionary)
				DebugUtils.shared.alert(message)
				completion?()
			}
	}

	func didAppear() {
		self.showLoaderIfNeeded()

		self.reloadAllContent()
        if self.deeplinkService.currentDeeplinks.isEmpty,
           Config.shouldOpenPrimeTravellerFirst {
            NotificationCenter.default.post(name: .primeTravellerRequested, object: nil)
        }
		self.processDeeplinkIfNeeded()
	}

	private var latestChatEditingEvent: ChatEditingEvent?

    private func openBanner(link: String, index: Int?) {
		FeedbackGenerator.vibrateSelection()

        if let index {
            self.analyticsReporter.didTapOnBannerDashboard(index: index, link: link)
        } else {
            self.analyticsReporter.didTapOnMainBanner(link: link)
        }

		if self.openBannerDeeplink(link) {
			return
		}

		let viewController = PrimeTravellerWebViewController(webLink: link, dismissesOnDeeplink: true)
		self.controller?.topmostPresentedOrSelf.present(viewController, animated: true)
	}

	private func openBannerDeeplink(_ link: String) -> Bool {
		guard let url = URL(string: link),
			  url.scheme == Config.appUrlSchemePrefix else {
			return false
		}

		self.controller?.showCommonLoader(hideAfter: 2)

		UIApplication.shared.open(url, options: [:]) { _ in
			delay(2) {
				self.controller?.view.hideLoadingIndicator()
			}
		}

		return true
	}

	private func openChat(
		for task: Task,
		messageGuidToOpen: String? = nil,
		onDismiss: @escaping () -> Void = {}
	) {
        guard
            let assistant = task.responsible,
            var chatParams = ChatAssembly.ChatParameters.make(
                for: task,
                assistant: assistant,
                activeFeedbacks: feedbackManager._rawFeedbacks
            )
        else { return }

		chatParams.messageGuidToOpen = messageGuidToOpen

		chatParams.onDidLoadInitialMessages = { [weak self] in
			self?.reloadTasks()
		}

		chatParams.onMessageSend = { [weak self] preview, _ in
			self?.reportChatMessageSent(preview)
			self?.updateChannel(with: .message(preview))
		}

		chatParams.onMessageSending = { [weak self] preview in
			self?.updateChannel(with: .message(preview))
		}

		chatParams.onDraftUpdated = { [weak self] event in
			self?.latestChatEditingEvent = event
		}

		var inputDecorations = [UIView]()
        let feedback = feedbackManager.feedbackForTask(task)
		if feedback != nil {
			inputDecorations.append(
				DefaultRequestItemFeedbackView.standalone(taskId: task.taskID, insets: [0, 5, 0, 0]) { [weak self] in
                    guard let self, let feedback = feedbackManager.feedbackForTask(task) else { return }

					self.analyticsReporter.didTapOnFeedbackInChat(
						taskId: task.taskID, feedbackGuid: feedback.guid^
					)
				}
			)
		}

        let chatViewControler = ChatAssembly.makeChatContainerViewController(
            with: chatParams,
			inputDecorationViews: inputDecorations,
            onDismiss: { [weak self] in
				onDismiss()

				guard let self else { return }

				self.loadUnreadCount()

				if let event = self.latestChatEditingEvent {
					self.updateChannel(with: event)
					self.latestChatEditingEvent = nil
				}
			}
        )

        let router = ModalRouter(
            source: self.controller?.topmostPresentedOrSelf,
            destination: chatViewControler,
            modalPresentationStyle: .pageSheet
        )
        router.route()
    }

	private func didTapOnTaskHeader(_ notification: Notification) {
		guard let taskId = notification.userInfo?["taskId"] as? Int else {
			DebugUtils.shared.log(sender: self, "didTapOnTaskHeader: FAILED to OPEN DETAILS: \(notification.userInfo?.description ?? "")")
			return
		}

		FeedbackGenerator.vibrateSelection()

		self.openTaskDetails(taskID: taskId)
	}

	private func didTapOnTaskMessage(_ notification: Notification) {
		let task = notification.userInfo?["task"] as? Task
		let taskId = notification.userInfo?["taskId"] as? Int

		guard let taskId else {
			DebugUtils.shared.log(sender: self, "didTapOnTaskMessage: FAILED to OPEN CHAT: \(notification.userInfo?.description ?? "")")
			return
		}

		FeedbackGenerator.vibrateSelection()
		if taskId == Task.aeroticketFlightTaskID, let task {
			self.openAeroticket(task)
			return
		}

        router?.openChat(taskID: taskId, messageGuidToOpen: nil) { }
	}

	private func didTapOnFeedback(_ notification: Notification) {
        guard let taskId = notification.userInfo?["taskId"] as? Int else {
            DebugUtils.shared.log(sender: self, "didTapOnTaskMessage: FAILED to OPEN FEEDBACK: \(notification.userInfo?.description ?? "")")
            return
        }
        
        guard
            let task = taskManager.task(from: .displayable, where: { $0.taskID == taskId }),
            let feedback = feedbackManager.feedbackForTask(task)
        else { return }
        
        let existingRating = notification.userInfo?["rating"] as? Int

		self.analyticsReporter.didTapOnFeedbackOnMainScreen(taskId: task.taskID, feedbackGuid: feedback.guid^)

        router?.openFeedback(feedback, existingRating: existingRating)

		FeedbackGenerator.vibrateSelection()
	}

	private func didSubmitFeedback(_ notification: Notification) {
		guard let guid = notification.userInfo?["guid"] as? String else {
			return
		}

        feedbackManager.replaceAllFeedbacks(with: feedbackManager._rawFeedbacks.skip({ $0.guid == guid }))
		self.reloadUI()
		self.reloadTasks()
	}

	private func openTaskDetails(taskID id: Int) {
		DebugUtils.shared.log(sender: self, "WILL openTaskDetails FOR taskID \(id)")

        guard let task = taskManager.task(from: .all, where: { $0.taskID == id }) else {
			DebugUtils.shared.log(sender: self, "FAILED TO openTaskDetails FOR taskID \(id), NO SUCH TASK!")
			return
		}

		let viewController = TaskDetailsViewController()
		viewController.update(with: task)

		self.controller?.topmostPresentedOrSelf.present(viewController, animated: true)
	}

	private func openAeroticket(_ task: Task) {
		guard let userInfo = task.events.first?.userInfo else {
			return
		}

		let ticket = userInfo["ticket"] as? Aerotickets.Ticket
		let flight = userInfo["flight"] as? Aerotickets.Flight

		guard let ticket, let flight else { return }

		let vc = AeroticketAssembly(ticket: ticket, flight: flight).make()
		self.controller?.topmostPresentedOrSelf.present(vc, animated: true)
	}

	func openTravellerWebView(webLink: String) {
		let webViewController = PrimeTravellerWebViewController(webLink: webLink)
		let router = ModalRouter(
			source: self.controller,
			destination: webViewController,
			modalPresentationStyle: .formSheet
		)
		router.route()
		self.analyticsReporter.openedPrimeTraveller()
		self.deeplinkService.clearAction(.cityguide(webLink))
	}

	private func openGeneralChat(message: String? = nil,
								 messageGuidToOpen: String? = nil,
								 onDismiss: @escaping () -> Void = {}) {
        
		guard let token = localAuthService.token?.accessToken,
			  let userID = localAuthService.user?.username else {
			return
		}
		let channelID = "N\(userID)"
		let customerID = "C\(userID)"

		let assistant = self.profileService.profile?.assistant ?? Assistant(firstName: "Default",
																			lastName: "Assistant")
		let params = ChatAssembly.ChatParameters(
			chatToken: token,
			channelID: channelID,
			channelName: "chat".localized,
			clientID: customerID,
			messageGuidToOpen: messageGuidToOpen,
			preinstalledText: message,
			assistant: assistant
		)

		let chatViewControler = ChatAssembly.makeChatContainerViewController(
			with: params,
			presentationViewController: controller,
			onDismiss: onDismiss
		)

		let router = ModalRouter(
			source: self.controller?.topmostPresentedOrSelf,
			destination: chatViewControler,
			modalPresentationStyle: .pageSheet
		)
		router.route()
	}

	@objc
	func didPullToRefresh() {
		self.mayRefreshRequestsList = true
		self.mayRetryRequests = true

		self.reloadAllContent()
	}

	private func reloadAllContent() {
		self.refreshContent(force: false, tasksOnly: false)
	}

	private func reloadTasks() {
		self.refreshContent(force: true, tasksOnly: true)
	}

	private func refreshContent(force: Bool, tasksOnly: Bool) {
		guard force || self.mayRefreshRequestsList else {
			return
		}

		self.mayRetryRequests = true
		self.mayRefreshRequestsList = false

		if !tasksOnly {
			self.loadServices()
			self.loadTaskTypes()
			self.loadBannersIfNeeded()
		}

		self.reloadFailedEventsIfNeeded()
		self.reloadFailedFileListsIfNeeded()
		self.loadActiveFeedbacks()
		self.loadAerotickets()

		self.tasksRetryDelay = 0
		self.channelsRetryDelay = 0

        if taskManager.hasTasks(in: .all) {
            self.fetchTasks(force: force, direction: .newer) { [weak self] _ in
				self?.fetchTasks(force: force, direction: .older)
			}
			return
		}

		Self.persistenseQueue.async {
			self.taskPersistenceService.clearEtags()
		}
		self.fetchTasks(direction: .older)
	}

	// MARK: - Private

	private func reloadFailedEventsIfNeeded() {
        let tasks = taskManager.tasks(from: .all) { task in
            taskIDsWaitingToLoadEvents.contains(task.taskID)
        }

		let splitTasks = tasks.split(by: self.limit)
		for tasks in splitTasks {
			self.fetchCalendarEvents(for: tasks)
		}
	}

	private func subscribeToNotifications() {
		Notification.onReceive(.tasksUpdateRequested) { [weak self] _ in
			self?.reloadTasks()
		}

		Notification.onReceive(.chatSDKDidEncounterError) { [weak self] notification in
			self?.trackChatError(notification)
		}

		Notification.onReceive(.restaurantSDKDidEncounterError) { [weak self] notification in
			self?.trackRestaurantError(notification)
		}

		Notification.onReceive(.viewDidDisappear) { [weak self] notification in
			guard let self = self, self.mayRefreshRequestsList, let controller = self.controller else {
				return
			}

			guard let viewController = notification.userInfo?["ViewController"] as? UIViewController,
					  viewController != controller else {
				return
			}

			guard NSStringFromClass(type(of: viewController)).hasPrefix("Prime") else {
				return
			}

			// Да. Аппиар троттлер и дисаппиар нотификейшен.
			// Мы вызываем обновление при СКРЫТИИ чилда.
			self.onMaybeAppearThrottler.execute()
		}

		Notification.onReceive(.shouldProcessDeeplink) { [weak self] _ in
			if self?.controller?.view.window == nil {
				return
			}

			self?.processDeeplinkIfNeeded()
		}

		Notification.onReceive(.chatDidSendMessage) { [weak self] notification in
			guard let message = notification.userInfo?["preview"] as? MessagePreview else {
				return
			}

			self?.reportChatMessageSent(message)
		}

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleOrderPaymentRequest(_:)),
			name: .orderPaymentRequested,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.handleTokenRefreshFailed),
			name: .failedToRefreshToken,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.taskWasUpdated(_:)),
			name: .taskWasUpdated,
			object: nil
		)

		Notification.onReceive(.loggedOut) { [weak self] _ in
			self?.handleLogout()
		}

		Notification.onReceive(.shouldClearCache) { [weak self] _ in
			self?.mayRetryRequests = false
		}

		Notification.onReceive(UIApplication.didBecomeActiveNotification) { [weak self] _ in
			self?.onMaybeAppearThrottler.execute()
		}

		Notification.onReceive(.didRefreshToken) { [weak self] _ in
            guard let self, self.chatBroadcastListener != nil else {
                return
            }
			self._chatMiscClient = nil
			self.chatBroadcastListener = nil
			self.startListeningToAnyChatUpdatesIfNeeded()
		}

		Notification.onReceive(.didTapOnTaskHeader) { [weak self] notification in
			self?.didTapOnTaskHeader(notification)
		}

		Notification.onReceive(.didTapOnTaskMessage) { [weak self] notification in
			self?.didTapOnTaskMessage(notification)
		}

		Notification.onReceive(.didTapOnFeedback) { [weak self] notification in
			self?.didTapOnFeedback(notification)
		}

		Notification.onReceive(.didSubmitFeedback) { [weak self] notification in
			self?.didSubmitFeedback(notification)
		}

        Notification.onReceive(.profileAskedToBeDismissed) { [weak self] notification in
            self?.router?.dismissProfile()
        }
	}

    private lazy var broadcastUpdateThrottler = Throttler(timeout: 1.5) {
        Self.channelQueue.async { [weak self] in
            guard let self else { return }

            let events = self.pendingChatEditingEvents
            self.pendingChatEditingEvents.removeAll()

            self.fetchTasks(direction: .newer) { [weak self] _ in
                self?.loadUnreadCount { [weak self] in
                    self?.updateChannels(with: events)
                }
            }
        }
    }

	private func startListeningToAnyChatUpdatesIfNeeded() {
		guard let token = localAuthService.token?.accessToken,
			  let userName = self.localAuthService.user?.username,
			  self.chatBroadcastListener == nil else {
			return
		}

		let clientID = "C\(userName)"
		self.chatBroadcastListener = ChatBroadcastListener(
			clientAppID: Config.chatClientAppID,
			chatBaseURL: Config.chatBaseURL,
			accessToken: token,
			clientID: clientID) { [weak self] preview in
				guard let self else { return }

				Self.channelQueue.async {
                    if let preview {
                        let event = ChatEditingEvent.message(preview)
                        self.pendingChatEditingEvents.append(event)
                        self.reportChatMessageReceived(preview)
                    }

                    self.broadcastUpdateThrottler.execute()
				}
			}
		
		self.chatBroadcastListener?.mayLoadDataForChannel = { [weak self] channelID in
			guard let self else { return false }

			if self.isGeneralChat(id: channelID) { return true }

            guard taskManager.tasks(from: .displayable, where: { task in
                guard let chatID = task.chatID else { return false }
                return task.chatID != nil && channelID.hasSuffix(chatID)
            }).first == nil else { return true }

			// значит, нам пришло уведомление чата от таски, которой у нас нет
			// давайте загрузим ее!
			if self.didLoadInitialTasks {
				self.fetchTasks(direction: .newer)
			}

			return false
		}
	}

	@ThreadSafe private var pendingTasksFetchDirections = Set<TasksFetchDirection>()

	fileprivate func fetchTasks(
        force: Bool = false,
        direction: TasksFetchDirection = .older,
        completion: ((Error?) -> Void)? = nil
    ) {
		self.channelsRetryDelay = 0

		let etag = direction == .older ? self.taskPersistenceService.minEtag :
										 self.taskPersistenceService.maxEtag

		if direction == .newer, etag == nil {
			completion?(nil)
			return
		}

		if etag == nil, !pendingTasksFetchDirections.isEmpty, !force {
            return
		}

		self.showLoaderIfNeeded()

		DebugUtils.shared.log(">ETAGS WILL FETCH \(direction == .older ? "OLDER" : "NEWER TASKS") FROM \(etag ?? "NULL")")

		attempt(on: Self.tasksNetworkingQueue) { [weak self] proceed in
			self?.loadTasksSequentially(
                force: force,
				direction: direction,
				continueLoading: {
					guard self?.mayRetryRequests == true else {
						return
					}
					proceed()
				},
				didFinishLoading: completion
			)
		}
	}

	private func loadTasksSequentially(
        force: Bool = false,
		cached: Bool = false,
		direction: TasksFetchDirection = .older,
		continueLoading: @escaping () -> Void,
		didFinishLoading: ((Error?) -> Void)? = nil
	) {
		if !force, self.pendingTasksFetchDirections.contains(direction) {
			return
		}

		self.pendingTasksFetchDirections.insert(direction)

		let etag = direction == .older ? self.taskPersistenceService.minEtag :
										 self.taskPersistenceService.maxEtag

		DebugUtils.shared.log(">ETAGS WILL LOAD DIR \(direction)               ETAG \(etag ?? "")")

		let language = Locale.primeLanguageCode

		let variables = [
			"lang": AnyEncodable(value: language),
			"limit": AnyEncodable(value: self.limit),
			"etag": AnyEncodable(value: etag),
			"order": AnyEncodable(value: direction.rawValue)
		]

		let endpoint = cached ? self.graphQLEndpoint.cache : self.graphQLEndpoint

		Self.tasksNetworkingQueue.promise {
			endpoint.request(
				query: GraphQLConstants.tasks,
				variables: variables
			).promise
		}.then { [weak self] (response: TasksResponse) -> Promise<[Task]> in
            var tasks = response.data.viewer.tasks
            
            if let thresholdDate = UserDefaults[string: "dropTasksOlderDate"]?.date("dd/MM/yyyy") {
                tasks = tasks.filter { $0.updatedAt > thresholdDate }
            }

			let etags = tasks.compactMap(\.etag)
			DebugUtils.shared.log(">ETAGS RECEIV MIN \(etags.min() ?? "") MAX \(etags.max() ?? "")")
			Self.persistenseQueue.async {
				self?.taskPersistenceService.recalculateExtremeEtags(with: tasks)
			}

			let newTasks = tasks.skip { $0.isDecodingFailed || $0.deleted }

            return Promise<[Task]> { [weak self] seal in
				guard let self else { return }
                
				self.loadUnreadCount {
					Self.persistenseQueue.async {
						self.taskPersistenceService.recalculateExtremeEtags(with: newTasks)
					}

					self.saveTasks(newTasks) { error in
						if let error {
							seal.reject(error)
							return
						}
						seal.fulfill(newTasks)
					}
				}
            }
		}
		.done(on: .main) { currentBatchOfTasks in
			self.mayShowBanners = true
			self.tasksRetryDelay = 0

			self.servePendingTaskOpeningDeeplink()
			self.servePendingFeedbackOpeningDeeplink()

			let tasksToLoadFiles = currentBatchOfTasks.todayAndFutureTasks
			self.fetchListsOfFiles(for: Set(tasksToLoadFiles.map(\.taskID)))

			guard currentBatchOfTasks.isEmpty else {
				Notification.post(.tasksDidLoad, userInfo: ["new_tasks": currentBatchOfTasks])
				self.fetchCalendarEvents(for: currentBatchOfTasks)
				self.reloadUI(completion: { self.hideLoaderIfNeeded() })
				continueLoading()
				return
			}

			self.reloadUI(completion: {
				self.controller?.hideTasksLoader()
				self.didFetchTasks(direction)
				didFinishLoading?(nil)
			})
		}
		.ensure {
			self.pendingTasksFetchDirections.remove(direction)
            self.startListeningToAnyChatUpdatesIfNeeded()
		}
		.catch(on: .main) { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) tasks batch loading failed",
					parameters: error.asDictionary
				)
			DebugUtils.shared.alert(sender: self, "TASKS LOADING FAILED ERROR: \(error)")
			delay(self.tasksRetryDelay) {
				if self.tasksRetryDelay > 10 {
					self.mayRefreshRequestsList = true
					self.cleanupAfterFetchingFailed()
					didFinishLoading?(error)
					return
				}
				self.tasksRetryDelay += 1
				continueLoading()
			}
		}
	}
    
    private func loadCrossSales() {
        let lang = Locale.primeLanguageCode
        let variables = ["lang": AnyEncodable(value: lang)]
        
        self.graphQLEndpoint.request(
            query: GraphQLConstants.crossSale,
            variables: variables
        ).promise.done(on: .main) { [weak self] (response: CrossSaleResponse) in
            self?.promoCategories = self?.fillPromoCategories(from: response) ?? [:]
            self?.reloadUI()
        }.catch { error in
            AnalyticsReportingService
                .shared.log(
                    name: "[ERROR] \(Swift.type(of: self)) cross sales failed",
                    parameters: error.asDictionary
                )
        }
    }

	private func loadAerotickets() {
		guard UserDefaults[bool: "aeroticketsEnabled"] else {
			self.aerotickets = .init(result: [])
			return
		}

		AeroticketsEndpoint.shared.getAerotickets().promise.done { tickets in
			self.aerotickets = tickets
			self.reloadUI()
		}.cauterize()
	}

    private func fillPromoCategories(from crossSaleResponse: CrossSaleResponse) -> [Int: [Int]] {
        var promoCategories: [Int: [Int]] = [:]

        for taskType in crossSaleResponse.data.viewer.taskTypesWithRelated {
            let taskTypeId = taskType.id
            let relatedIds = taskType.related.map { $0.id }

            promoCategories[taskTypeId] = relatedIds
        }

        return promoCategories
    }

	private func didFetchTasks(_ direction: TasksFetchDirection) {
		self.controller?.hideTasksLoader()
		self.mayRefreshRequestsList = true

		self.callPostFetchCompletionsByTasks()
		self.postFetchCompletionsByTasks.removeAll()
	}

	private func cleanupAfterFetchingFailed() {
		self.controller?.hideTasksLoader()
		self.postFetchCompletionsByTasks.removeAll()
		self.reloadUI()
	}

	private func callPostFetchCompletionsByTasks() {
		self.postFetchCompletionsByTasks.values.forEach { completion in
			completion()
		}
	}

    private(set) var eventsByDays: HomeViewModelEventsMap = .init()

	private func updateViewController(
		didSetupViewModel: (() -> Void)? = nil,
		completion: (() -> Void)? = nil
	) {
        
		Self.viewModelQueue.async { [weak self] in
			guard let self else { return }

            let tasksCount = taskManager.numberOfTasks(in: .all)
            let taskEventsCount = taskManager.tasks(from: .all).flatMap(\.events).count

			DebugUtils.shared.log(sender: self, "TIRESOME WILL CREATE VIEWMODEL FOR \(tasksCount) TASKS WITH \(taskEventsCount) EVENTS")

            let mayShowBanners = self.mayShowBanners || taskManager.hasTasks(in: .displayable)

			let generalChatUnreadMessagesCount = self.unreadInfo
				.first{ self.isGeneralChat(id: $0.channelId) }?
				.unreadCount ?? 0

            var tasks = taskManager.tasks(from: .all)
            var activeTasks = taskManager.tasks(from: .active)
            var displayableTasks = taskManager.tasks(from: .displayable)

			if UserDefaults[bool: "tasksUnreadOnly"] {
				tasks = tasks.filter{ $0.unreadCount > 0 }
				activeTasks = activeTasks.filter{ $0.unreadCount > 0 }
				displayableTasks = displayableTasks.filter{ $0.unreadCount > 0 }
			}

            if let specificTasks = UserDefaults[string: "specific_tasks_to_show"], !specificTasks.isEmpty {
                let taskIdsArray = specificTasks.components(separatedBy: ",").compactMap{ Int($0) }
                if !taskIdsArray.isEmpty {
                    tasks = tasks.filter { task in taskIdsArray.contains(where: { $0 == task.taskID }) }
                    activeTasks = activeTasks.filter { task in taskIdsArray.contains(where: { $0 == task.taskID }) }
                    displayableTasks = displayableTasks.filter { task in taskIdsArray.contains(where: { $0 == task.taskID }) }
                }
            }

			let viewModel = HomeViewModel(
				allTasks: tasks,
				activeTasks: activeTasks,
				displayableTasks: displayableTasks,
				aerotickets: self.aerotickets,
				banners: mayShowBanners ? self.bannerViewModels : [],
                feedbacks: feedbackManager._rawFeedbacks,
                promoCategories: self.promoCategories,
				generalChatUnreadMessagesCount: generalChatUnreadMessagesCount
			)

			self.eventsByDays = viewModel.eventsByDays

			Notification.post(.didUpdateHomeViewModel, userInfo: ["viewModel": viewModel])

			onMain { [weak self] in
				didSetupViewModel?()
				self?.controller?.set(viewModel: viewModel)
				completion?()
			}
		}
	}
	
	private lazy var uiReloadEnqueuer = BatchEnqueuer()
	private lazy var filesUIReloadThrottler = Throttler(timeout: 1) { [weak self] in
		self?.reloadUI()
	}

	private lazy var fileListsEnqueuer = BatchEnqueuer(
		maxCount: 1,
		onBatchProcessed: { [weak self] _ in
			guard let self else { return }
			Self.persistenseQueue.async { [weak self] in
				guard let self else { return }
                taskManager.replaceAllTasks(
                    with: fillTasksWithAttachedFiles(taskManager.tasks(from: .all)),
                    feedbacks: feedbackManager._rawFeedbacks
                )
				self.filesUIReloadThrottler.execute()
			}
		}
	)

	private lazy var fileContentsEnqueuer = BatchEnqueuer(maxCount: 2)

	private let fileListsLock = NSLock()

	private func fillTasksWithAttachedFiles(_ tasks: [Task]) -> [Task] {
		let tasks = tasks.map { task in
			if let files = self.taskIDsToFileLists[task.taskID] {
				var task = task
				task.attachedFiles = files
				return task
			}
			return task
		}

		return tasks
	}

	private func fetchListsOfFiles(for taskIDs: Set<Int>) {
		// в комплишене группы перерисовка вью-модели и экрана
		for id in taskIDs {
			self.fileListsLock.withLock {
				_ = self.taskIDsToReloadFileLists.insert(id)
			}

			self.fileListsEnqueuer.enqueue { [weak self] enqueuer in
				guard let self else {
					enqueuer.runNext()
					return
				}

				self.filesService
					.list(forTask: id)
					.done(on: .main) { filesResponse in
						guard let files = filesResponse.data else { return }
						self.fileListsLock.withLock {
							self.taskIDsToFileLists[id] = files
							self.taskIDsToReloadFileLists.remove(id)
						}

						self.loadContentFor(files: files)
					}
					.catch { error in
						AnalyticsReportingService
							.shared.log(
								name: "[ERROR] Task attachemnts list fetch failed",
								parameters: error.asDictionary.appending("taskId", id)
							)
					}.finally {
						enqueuer.runNext()
					}
			}
		}
    }

	private func loadContentFor(files: [FilesResponse.File]) {
		files.forEach { file in
			self.fileUIDsToReloadContents.insert(file.cacheKey)
			self.fileContentsEnqueuer.enqueue { [weak self] enqueuer in
				self?.loadData(for: file) { enqueuer.runNext() }
			}
		}
	}

	private func loadData(for file: FilesResponse.File, completion: (() -> Void)?) {
		self.filesService.downloadData(uuid: file.uid)
			.done { data in
				if data.isEmpty { return }
				self.fileUIDsToReloadContents.remove(file.cacheKey)
				DocumentsCacheService.shared.save(cacheKey: file.cacheKey, data: data)
			}
			.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] Task attachemnt data fetch failed",
						parameters: error.asDictionary.appending("uid", file.cacheKey)
					)
			}
			.finally {
				completion?()
			}
	}
	
	private func reloadUI(
		fetchTasksDB: Bool = false,
		didSetupViewModel: (() -> Void)? = nil,
		completion: (() -> Void)? = nil
	) {
		self.uiReloadEnqueuer.enqueue { [self] enqueuer in
            taskManager.replaceAllTasks(
                with: fillTasksWithAttachedFiles(taskManager.tasks(from: .all)),
                feedbacks: feedbackManager._rawFeedbacks
            )

			let reloadUIBlock = {
				onMain {
					self.updateViewController(didSetupViewModel: didSetupViewModel) {
						completion?()
						enqueuer.runNext()
					}
				}
			}
            guard fetchTasksDB else {
                reloadUIBlock()
                return
            }
			Self.persistenseQueue.promise {
				self.taskPersistenceService.retrieve()
			}.done { [weak self] tasks in
                guard let self else { return }
                taskManager.replaceAllTasks(with: tasks, feedbacks: feedbackManager._rawFeedbacks)
				self.reloadFailedEventsIfNeeded()
				self.reloadFailedFileListsIfNeeded()
				reloadUIBlock()
			}.catch(on: .main) { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) reloadUI retrieve tasks failed",
						parameters: error.asDictionary
					)
				completion?()
				enqueuer.runNext()
			}
		}
	}

	private func updateChannel(
		with event: ChatEditingEvent,
		completion: (() -> Void)? = nil
	) {
		self.updateChannels(with: [event], completion: completion)
	}

	private func updateChannels(
		with events: [ChatEditingEvent],
		completion: (() -> Void)? = nil
	) {
		Self.channelQueue.async { [weak self] in
			guard let self else {
				completion?()
				return
			}

            var updatedTasksMap = [Int: Task]()

			for event in events {
				var task: Task?
				var isGeneralChat = false

                var taskID: Int

                switch event {
                    case .message(let preview):
                        taskID = Int(preview.channelID.replacing(regex: "^\\D", with: "")) ?? -1
                        let existingTask = taskManager.task(from: .all, where: { $0.taskID == taskID })
                        isGeneralChat = self.isGeneralChat(id: preview.channelID)

                        guard var existingTask,
                              let message = self.message(from: preview) else {
                            break
                        }
                        var lastChatMessage = existingTask.lastChatMessage
                        let previewMessage = self.message(from: preview)

                        if lastChatMessage == previewMessage { return }
                        defer {
                            task = existingTask
                        }

                        if preview.status == .draft {
                            let draft = mostFit(message, existingTask.latestDraft) { $0.timestamp > $1.timestamp }
                            existingTask.latestDraft = draft
                            break
                        }

                        if !preview.isIncome {
                            existingTask.latestDraft = nil
                        }

                        lastChatMessage = mostFit(message, existingTask.lastChatMessage) { $0.timestamp > $1.timestamp }

                        existingTask.lastChatMessage = lastChatMessage

                    case .empty(let channelID):
                        taskID = Int(channelID.replacing(regex: "^\\D", with: "")) ?? -1
                        let existingTask = taskManager.task(from: .all, where: { $0.taskID == taskID })
                        isGeneralChat = self.isGeneralChat(id: channelID)

                        guard var existingTask else {
                            break
                        }

                        existingTask.latestDraft = nil
                        task = existingTask
                }

				guard let task else {
					if isGeneralChat { onMain { self.reloadUI(completion: completion) } }
					continue
				}

                updatedTasksMap[taskID] = task
			}

			if updatedTasksMap.isEmpty {
				completion?()
				return
			}

            let updatedTasks = Array(updatedTasksMap.values)

            let tasksToSave = taskManager.tasks(from: .all).map { existingTask in
				let updatedTask = updatedTasks.first { $0.taskID == existingTask.taskID }
				return updatedTask ?? existingTask
            }

            taskManager.replaceAllTasks(with: tasksToSave, feedbacks: feedbackManager._rawFeedbacks)

			self.saveTasks(tasksToSave, enforceDrafts: true) { [weak self] _ in
				onMain {
					self?.reloadUI(completion: completion)
				}
			}
		}
	}

	private func message(from preview: MessagePreview) -> Message? {
		guard
			let userID = localAuthService.user?.username,
			let type = preview.content.last?.processed,
			let content = preview.content.last?.processed?.previewString else {
			return nil
		}

		return Message(
			guid: preview.guid,
			clientId: preview.clientID ?? "C\(userID)",
			channelId: preview.channelID,
			source: preview.source.rawValue,
			timestamp: preview.timestamp,
			status: preview.status,
			type: type.messageType,
			content: content,
			messenger: preview.source.rawValue
		)
	}

	@objc
	private func handleOrderPaymentRequest(_ notification: Notification) {
		guard let order = notification.userInfo?["order"] as? Order else {
			return
		}

        router?.openPayment(orderID: order.id)
	}

	private func showLoaderIfNeeded() {
		if taskManager.hasTasks(in: .all) {
			return
		}

		self.controller?.showTasksLoader()
	}
}

// MARK: - HomeRouterDelegate

extension HomePresenter: HomeRouterDelegate {
	var navigationController: UINavigationController? {
		self.controller?.navigationController
	}
	
    var profileViewController: UIViewController { profileTabsViewController }
    
    func openChat(taskID: Int, messageGuidToOpen: String?, onDismiss: @escaping () -> Void) {
        DebugUtils.shared.log(sender: self, "WILL openChat FOR taskID \(taskID)")
        
        if let task = taskManager.task(from: .all, where: { $0.taskID == taskID }) {
            DebugUtils.shared.log(sender: self, "WILL openChat FOR taskID \(taskID), TASK FOUND! ID: \(task.taskID)")
            openChat(for: task, messageGuidToOpen: messageGuidToOpen, onDismiss: onDismiss)
            analyticsReporter.tappedEventInCalendar(mode: .compact)
            return
        }
        
        DebugUtils.shared.log(sender: self, "WILL openChat FOR taskID \(taskID), TASK NOT FOUND! TRY TO LOAD!")
        
        reloadTasks()
        
        controller?.showCommonLoader()
        postFetchCompletionsByTasks[taskID] = { [weak self] in
            guard let self else { return }
            
            guard let task = taskManager.task(from: .all, where: { $0.taskID == taskID }) else {
                DebugUtils.shared.log(sender: self, "WILL openChat FOR taskID \(taskID). TASKS LOADED, BUT STILL NOT FOUND! DISMISS!")
                controller?.hideTasksLoader()
                return
            }
            
            DebugUtils.shared.log(sender: self, "WILL openChat FOR taskID \(taskID). TASKS LOADED AND FOUND!")
            
            openChat(for: task, onDismiss: onDismiss)
            postFetchCompletionsByTasks.removeValue(forKey: taskID)
            if postFetchCompletionsByTasks.isEmpty {
                controller?.hideTasksLoader()
            }
        }
    }
    
    func unpaidOrder(withID orderID: Int) -> Order? {
        taskManager.tasks(from: .displayable)
            .flatMap(\.ordersWaitingForPayment)
            .first { $0.id == orderID }
    }
    
    func paymentDelegateDidFinish() {
        tasksRetryDelay = 0
        channelsRetryDelay = 0
        fetchTasks()
    }
}

// MARK: - HomeTaskManagerDelegate

extension HomePresenter: HomeTaskManagerDelegate {
    func taskManagerHasDisplayableTasks(_ manager: HomeTaskManager) {
        onMain { [weak self] in
            self?.controller?.hideTasksLoader()
        }
    }
}

extension HomePresenter {
	private func servePendingTaskOpeningDeeplink() {
		guard let pending = self.pendingTaskOpeningDeeplink else {
			return
		}

		let taskId = pending.0
        if taskManager.task(from: .all, where: { $0.taskID == taskId }) != nil {
			pending.1()
			self.pendingTaskOpeningDeeplink = nil
		}
	}

	private func servePendingFeedbackOpeningDeeplink() {
		guard let pending = self.pendingFeedbackOpeningDeeplink else {
			return
		}

		let guid = pending.0
		guard let feedback = self.feedbackManager.feedbackWithGUID(guid) else {
			return
		}

		let block = pending.1
		block(feedback)

		self.pendingFeedbackOpeningDeeplink = nil
	}

	@objc
	private func processDeeplinkIfNeeded() {
		guard let deeplink = self.deeplinkService.currentDeeplinks.last else { return }

		switch deeplink {
			case .home:
				self.dismissAnyPresentedAnd {
					self.controller?.navigationController?.popToRootViewController(animated: true)
					self.deeplinkService.clearLatestAction()
				}
			case .chatMessage(text: let text):
				self.dismissAnyPresentedAnd {
					self.router?.openChat(message: text, onDismiss: { })
					self.analyticsReporter.deeplinkedFromWebIntoChat()
					self.deeplinkService.clearLatestAction()
				}
			case .generalChat(let messageGuidToOpen):
				self.dismissAnyPresentedAnd {
					self.openGeneralChat(messageGuidToOpen: messageGuidToOpen)
					self.deeplinkService.clearLatestAction()
				}
			case .task(let id, let messageGuidToOpen):
				let block = {
					self.dismissAnyPresentedAnd {
						self.controller?.hideCommonLoader()
						self.openChat(taskID: id, messageGuidToOpen: messageGuidToOpen) { }
						self.deeplinkService.clearLatestAction()
					}
				}

				let taskToOpen = taskManager.task(from: .all, where: { $0.taskID == id })
				if taskToOpen == nil {
					self.controller?.showCommonLoader(hideAfter: 2)
					self.pendingTaskOpeningDeeplink = (id, block)
					return
				}

				block()
			case .profile:
				self.deeplinkService.clearLatestAction()
				if let controllers = self.controller?.navigationController?.viewControllers,
				   controllers.contains(self.profileTabsViewController) {
					return
				}
				self.dismissAnyPresentedAnd {
					self.router?.openProfile()
				}
			case .cityguide(let webLink):
				if let viewController = self.cityGuideViewController {
					viewController.webLink = webLink
					self.deeplinkService.clearAction(.cityguide(webLink))
					self.analyticsReporter.openedPrimeTraveller()
					return
				}

				self.dismissAnyPresentedAnd {
					self.openTravellerWebView(webLink: webLink)
				}
			case .tasksCompleted:
				self.dismissAnyPresentedAnd {
					self.router?.openCompletedTasks()
				}
			case .createTask:
				self.dismissAnyPresentedAnd {
					self.router?.openRequestCreation(message: nil)
				}
			case .feedback(guid: let guid):
				if let feedback = feedbackManager.feedbackWithGUID(guid) {
					self.router?.openFeedback(feedback, existingRating: nil)
					self.deeplinkService.clearAction(deeplink)
					return
				}

				self.controller?.showCommonLoader(hideAfter: 2)

				self.pendingFeedbackOpeningDeeplink = (guid, { [weak self] feedback in
					guard let self else { return }
					self.dismissAnyPresentedAnd {
						self.controller?.hideCommonLoader()
						self.router?.openFeedback(feedback, existingRating: nil)
						self.deeplinkService.clearAction(deeplink)
					}
				})
		}
	}
    
	private func dismissAnyPresentedAnd(perform completion: @escaping () -> Void) {
		let animated = UIApplication.shared.applicationState == .active

		if self.controller?.presentedViewController != nil {
			self.controller?.dismiss(animated: animated, completion: completion)
			return
		}
		completion()
	}

	private func fillTasksWithEvents(
		_ tasks: [Task],
		_ events: [CalendarEvent]
	) -> (tasks: [Task], removedEvents: [CalendarEvent], existingEvents: [CalendarEvent]) {
		var removedEvents = [CalendarEvent]()
		var existingEvents = [CalendarEvent]()
		let groupedEvents = Dictionary(grouping: events, by: \.taskId)

		let updatedTasks = tasks.compactMap { (task: Task) -> Task? in
			let events = groupedEvents[task.taskID]^

			var task = task
			task.events = events

            let oldTask = taskManager.task(from: .all) { $0.taskID == task.taskID }
			let oldEvents = oldTask?.events ?? []

			let currentRemovedEvents: [CalendarEvent] = oldEvents.filter { old in
				!events.contains{ $0.id == old.id  }
			}

			removedEvents.append(contentsOf: currentRemovedEvents)
			existingEvents.append(contentsOf: task.events)

			return task
		}

		return (updatedTasks, removedEvents, existingEvents)
	}

	private func fillNewTasksWithLatestChatContent(_ newTasks: [Task], addEvents: Bool = true) -> [Task] {
		return newTasks.map { newTask in

            guard let oldTask = taskManager.task(from: .all, where: { $0.taskID == newTask.taskID }) else { return newTask }

			var newestTask = newTask
            if oldTask.updatedAt > newTask.updatedAt {
                newestTask = oldTask
            }

			let currentDraft = oldTask.latestDraft
			if addEvents {
				newestTask.events = oldTask.events
			}

			if let draft = currentDraft {
				newestTask.latestDraft = draft
				return newestTask
			}

			let lastChatMessage = mostFit(newestTask.lastChatMessage, oldTask.lastChatMessage) { $0.timestamp > $1.timestamp }

			newestTask.lastChatMessage = lastChatMessage

			return newestTask
		}
	}

	@discardableResult
	private func mergeTasksUnreadInfo() -> [Task] {
        var taskIdsToTasksMap = [Int: Task]()

        // Tasks With Changed Unread Count
		self.unreadInfo.forEach { info in
            guard let taskID = Int(info.channelId.replacing(regex: "^\\D", with: "")) else {
                return
            }
            
            let task = taskManager.task(from: .all) { $0.taskID == taskID }
            guard var task else { return }

			if task.unreadCount == info.unreadCount {
				return
			}
            
			task.unreadCount = info.unreadCount
            taskIdsToTasksMap[taskID] = task
		}
        
        // Tasks With All Messages Read
        taskManager
            .tasks(from: .all) { task in
                if task.unreadCount == 0 { return false }

                let unreadInfo = self.unreadInfo.first {
                    let taskID = Int($0.channelId.replacing(regex: "^\\D", with: ""))
                    return task.taskID == taskID
                }
                let messagesAreNowAllRead = unreadInfo == nil || unreadInfo?.unreadCount == 0
                return messagesAreNowAllRead
            }
            .forEach { task in
                var _task = task
                _task.unreadCount = 0
                taskIdsToTasksMap[task.taskID] = _task
            }

        let mergeResult = Array(taskIdsToTasksMap.values)
		return mergeResult
	}

	private func saveTasks(
		_ newTasks: [Task],
		enforceDrafts: Bool = false,
		enforceEvents: Bool = true,
		completion: ((Error?) -> Void)? = nil
	) {
		if newTasks.isEmpty {
			onMain { completion?(nil) }
			return
		}

		Self.persistenseQueue.async { [weak self] in
			guard let self else { return }

			var tasks = self.fillNewTasksWithLatestChatContent(newTasks, addEvents: enforceEvents)

            taskManager.replaceAllTasks(
                with: merge(tasks: tasks, into: taskManager.tasks(from: .all)).skip(\.deleted),
                feedbacks: feedbackManager._rawFeedbacks
            )

			let unreadTasks = self.mergeTasksUnreadInfo()
            taskManager.replaceAllTasks(
                with: merge(tasks: unreadTasks, into: taskManager.tasks(from: .all)),
                feedbacks: feedbackManager._rawFeedbacks
            )

			tasks.append(contentsOf: unreadTasks)
			tasks.uniquify(by: \.taskID)

			Self.persistenseQueue.promise {
				self.taskPersistenceService.save(tasks: tasks)
			}.done(on: .main) {
				completion?(nil)
			}.catch(on: .main) { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) reloadUI saveTasks failed",
						parameters: error.asDictionary
					)
				completion?(error)
			}
		}
	}

	private func merge(tasks newTasks: [Task], into oldTasks: [Task]) -> [Task] {
		let newTaskIds = Set(newTasks.map(\.taskID))
		
		var resultingTasks = oldTasks.skip { newTaskIds.contains($0.taskID) }
		resultingTasks.append(contentsOf: newTasks)
		resultingTasks.sort{ $0.isMoreRecentlyUpdated(than: $1) }

		return resultingTasks
	}

	@objc
	private func handleTokenRefreshFailed() {
		self.mayRetryRequests = false
	}

	@objc
	private func handleLogout() {
		UserDefaults[bool: "HAS_SHOWN_HOME_SCREEN_PREVIOUSLY"] = false
		self.mayRetryRequests = false
	}

	@objc
	private func taskWasUpdated(_ notification: Notification) {
		guard let task = notification.userInfo?["task"] as? Task else {
			return
		}

		self.saveTasks([task]) { _ in
			NotificationCenter.default.post(
				name: .taskWasSuccessfullyPersisted,
				object: nil,
				userInfo: ["task": task]
			)
			self.reloadUI()
		}
	}
}

private extension HomePresenter {
	func openChatURL(_ url: URL) -> Bool {
		if url.absoluteString.contains(Config.travellerEndpoint) ||
		   url.host^.contains(Config.branchLinkHost)
		{
			let webViewController = PrimeTravellerWebViewController(
				webLink: url.absoluteString,
				dismissesOnDeeplink: false
			)
			self.cityGuideViewController = webViewController
			self.controller?.topmostPresentedOrSelf.present(webViewController, animated: true)
			self.analyticsReporter.openedPrimeTraveller()
			return true
		}

		guard url.scheme^.hasPrefix("http") else {
			UIApplication.shared.open(url)
			return true
		}

		let router = SafariRouter(
			url: url,
			source: self.controller?.topmostPresentedOrSelf
		)

		router.route()

		return true
	}
}

private extension HomePresenter {
	private func task(channelID: String) -> Task? {
		let taskID = Int(channelID.replacing(regex: "^\\D", with: "")) ?? -1
        let task = taskManager.task(from: .all) { $0.taskID == taskID }
		return task
	}

	private func taskCategory(for preview: MessagePreview) -> String? {
		var category: String?
		let chatID = preview.channelID

		let task = self.task(channelID: chatID)
		if let taskType = task?.taskType {
			category = "\(taskType.id) (\(taskType.localizedName(lang: "en")))"
		}

		return category
	}
	
	private func reportChatMessageSent(_ preview: MessagePreview?) {
		self.reportChatMessageToAnalytics(preview) { chatID, contentType, category in
			self.analyticsReporter.didSendChatMessage(
				chatID: chatID, contentType: contentType, category: category
			)
		}
	}

	private func reportChatMessageReceived(_ preview: MessagePreview?) {
		self.reportChatMessageToAnalytics(preview) { chatID, contentType, category in
			self.analyticsReporter.didReceiveChatMessage(
				chatID: chatID, contentType: contentType, category: category
			)
		}
	}

	private func reportChatMessageToAnalytics(
		_ preview: MessagePreview?,
		_ action: (String, String, String?) -> Void
	) {
		guard let preview else { return }

		if self.reportedMessageGUIDs.contains(preview.guid.lowercased()) {
			return
		}

		let chatID = preview.channelID
		if self.isGeneralChat(id: chatID) { return }

		let task = self.task(channelID: chatID)

		guard preview.status.isRemote else {
			return
		}

		if let status = task?.lastChatMessage?.status, status.isRemote {
			if preview.guid.lowercased() == task?.lastChatMessage?.guid.lowercased() {
				return
			}
		}

		self.reportedMessageGUIDs.insert(preview.guid.lowercased())

		let category = self.taskCategory(for: preview)
		let contentType = preview.content.compactMap{ $0.processed?.debugDescription }.joined(separator: ", ")

		action(chatID, contentType, category)
	}

	private func isGeneralChat(id: String) -> Bool {
		let id = id.lowercased()
		let username = self.profileService.profile?.username ?? ""
		return id == "n\(username)"
	}
}

extension DebugUtils: ChatSDK.DebugLogger, RestaurantSDK.DebugLogger {
	func log(sender: AnyObject?, prefix: String, _ items: Any...) {
		self.log(sender: sender, items, prefix: prefix)
	}
}

// swiftlint:enable file_length
