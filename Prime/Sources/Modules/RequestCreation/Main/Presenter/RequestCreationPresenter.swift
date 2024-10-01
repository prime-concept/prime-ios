// swiftlint:disable file_length

import ChatSDK
import Foundation
import PromiseKit
import UIKit
import RestaurantSDK
import SafariServices

enum RequestCreationError: LocalizedError {
    case blankFields
    case serverResponseFailure

    var errorDescription: String? {
        switch self {
        case .blankFields:
            return "form.validation.error".localized
        case .serverResponseFailure:
            return "form.server.error".localized
        }
    }
}

// swiftlint:disable trailing_whitespace
protocol RequestCreationPresenterProtocol {
    func didLoad()
	func didAppear()
    func didSelectTask(at index: Int)
}

final class RequestCreationPresenter: RequestCreationPresenterProtocol {
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let taskPersistenceService: TaskPersistenceServiceProtocol
	private let profileService: ProfileServiceProtocol
    private let analyticsReporter: AnalyticsReportingService
	private let deeplinkService: DeeplinkService
	private let servicesEndpoint: ServicesEndpointProtocol

	private weak var chatContainerViewController: ChatContainerViewController?
	private var chatViewController: ChatViewController? {
		self.chatContainerViewController?.chatViewController
	}

    private var tasks: [Task] = []
	private var nearestTaskIndex: Int? = nil
	private var selectedCategoryId: Int? = nil
	private var isBeingDismissedAsRequestCreated: Bool = false

	private var keyboardHeightTracker: KeyboardHeightTracker?
	private lazy var chatOverlayView = with(UIView()) { view in
		view.addSubview(self.chatIsUnavailableView)
		self.chatIsUnavailableView.make(.edges, .equalToSuperview)
	}

	private lazy var chatIsUnavailableView = with(RequestCreationDefaultOverlayView()) { view in
		view.update(with: RequestCreationDefaultOverlayView.ViewModel(
			title: "createTask.chooseExisting".localized,
			subtitle: "createTask.createNew".localized)
		)
		view.isHidden = true
	}

	private var preinstalledText: String?
	private var taskIdWaitingToOpenChat: Int?
    private var requestFormViewController: RequestFormViewController?

    weak var controller: RequestCreationViewProtocol?
	private var didAppearWaitingBlocks: [(() -> Void)] = []

	private lazy var hotelBookingViewController: HotelFormViewControllerProtocol = {
        let assembly = HotelFormAssembly()
        let viewController = assembly.make()
		return viewController
	}()

	private var services: Services?
	private var aviaBookingViewController: AviaFormViewControllerProtocol?
    private var vipLoungeViewController: VIPLoungeFormViewControllerProtocol?

	@PersistentCodable(fileName: "Home-Feedbacks")
	private var activeFeedbacks = [ActiveFeedback]()

    var numberOfTasks: Int {
        self.tasks.count
    }

    init(
		preinstalledText: String?,
        taskPersistenceService: TaskPersistenceServiceProtocol,
		profileService: ProfileServiceProtocol,
        graphQLEndpoint: GraphQLEndpointProtocol,
		servicesEndpoint: ServicesEndpointProtocol,
        analyticsReporter: AnalyticsReportingService,
		deeplinkService: DeeplinkService = .shared
    ) {
		self.preinstalledText = preinstalledText
        self.taskPersistenceService = taskPersistenceService
		self.profileService = profileService
		self.deeplinkService = deeplinkService
        self.graphQLEndpoint = graphQLEndpoint
        self.analyticsReporter = analyticsReporter
		self.servicesEndpoint = servicesEndpoint
    }

    func didLoad() {
		self.subscribeToNotifications()
		self.loadServices()
		self.loadTasks()
		self.setupChatOverlay()
		self.processDeeplinkIfNeeded()
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

	private func loadTasks(completion: (() -> Void)? = nil) {
		self.taskPersistenceService.retrieve()
			.done { [weak self] tasks in
				guard let self = self else {
					return
				}

				let tasks = tasks.todayAndFutureTasks
				self.set(tasks: tasks)

				self.controller?.update(
					with: .init(
						header: self.makeHeaderViewModel(selected: .new),
						categories: self.makeCategoriesViewModel(),
						tasks: self.tasks.map(self.taskViewModel(from:)),
						nearestTaskIndex: self.nearestTaskIndex
					)
				)
			}
			.ensure {
				completion?()
			}
			.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) taskPersistenceService.retrieve failed",
						parameters: error.asDictionary
					)
			}
	}

	private func todayAndFutureTasks(from tasks: [Task]) -> [Task] {
		let tasks = tasks.skip(\.completed)
		let today = Date().down(to: .day)
		let recentTasks = tasks.filter {
			guard let date = $0.taskDate else {
				return false
			}
			return date >= today
		}
		return recentTasks
	}

	func didAppear() {
		self.didAppearWaitingBlocks.forEach{ $0() }
		self.didAppearWaitingBlocks.removeAll()
	}

	private var hasPendingCustomFormDeeplink: Bool {
		let deeplink = self.deeplinkService.currentDeeplinks.last

		if case .createTask(let type, _) = deeplink {
			if self.isCustomRequestCategory(type.id) {
				return true
			}
		}

		return false
	}

	private func processDeeplinkIfNeeded() {
		guard let deeplink = self.deeplinkService.currentDeeplinks.last else {
			return
		}

		switch deeplink {
			case .createTask(let type, let queryItems):
				self.selectedCategoryId = type.id
				let userInfo = queryItems?.reduce([String: String]()) {
					var userInfo = $0; userInfo[$1.name] = $1.value
					return userInfo
				}
				self.showCreationForm(forCategoryId: type.id, userInfo: userInfo, dismissInputAccessory: false)
				self.deeplinkService.clearAction(deeplink)
            case .chatMessage(_):
                self.dismissOverlay()
                self.deeplinkService.clearAction(deeplink)
			default:
				return
		}
	}

	private var shouldResetCreationViewController = false

    private func setupChatOverlay() {
        guard let controller else { return }

        self.chatOverlayView.translatesAutoresizingMaskIntoConstraints = false
        self.chatOverlayView.isHidden = false

		let parameters = self.makeChatParameters()

        let chatContainerViewController = ChatAssembly.makeChatContainerViewController(
            with: parameters,
            presentationViewController: controller,
            inputAccessoryView: controller.requestInputView,
            overlayView: self.chatOverlayView
        )

        self.chatContainerViewController = chatContainerViewController
        controller.displayChild(viewController: chatContainerViewController)
    }

	private func makeChatParameters() -> ChatAssembly.ChatParameters {
		let userID = LocalAuthService.shared.user?.username ?? ""
		let assistant = self.profileService.profile?.assistant ??
		Assistant(firstName: "Default", lastName: "Assistant")

		let mayShowKeyboard = !self.hasPendingCustomFormDeeplink

		var params = ChatAssembly.ChatParameters(
			chatToken: LocalAuthService.shared.token?.accessToken ?? "",
			channelID: "N\(userID)",
			channelName: "Чат",
			clientID: "C\(userID)",
			preinstalledText: self.preinstalledText,
			mayShowKeyboardWhenAppeared: mayShowKeyboard,
			assistant: assistant
		)

		params.onDecideIfMaySendMessage = { [weak self] preview, decisionBlock in
			guard let self else {
				decisionBlock(true)
				return
			}

			// Этот метод вызывается для каждого вложения в рамках сообщения. Текст это тоже вложение.
			// Но сперва он вызывается с превью == MessagePreview.outcomeStub,
			// чтобы решить, а посылать ли сообщение вообще.
			// То есть вызовов будет на 1 больше, чем вложений.
			let isStub = preview?.guid == MessagePreview.outcomeStub.guid
			let isCustomRequest = self.isCustomRequestCategory(self.selectedCategoryId)

			// Если isCustomRequest, то мы не посылаем в дженерал никаких сообщений.
			// Мы создаем запрос, дожидаемся когда у его таски появится чат,
			// открываем чат и посылаем сообщения уже в этот чат.
			if isCustomRequest {
				self.customRequestDebouncer.reset()
				decisionBlock(false)
				return
			}

			if isStub {
				decisionBlock(true)
				return
			}

			defer {
				self.resetSelectedCategory()
			}

			if let content = preview?.content.first, content.raw.type == .text {
				decisionBlock(true)
				return
			}

			guard let stub = self.newRequestStub else {
				decisionBlock(true)
				return
			}

			self.chatViewController?.sendMessage(text: stub) { _ in
				decisionBlock(true)
			}
		}

		params.onModifyTextBeforeSending = { [weak self] text in
			guard let self else { return text }

			if self.isCustomRequestCategory(self.selectedCategoryId) {
				return text
			}

			if let stub = self.newRequestStub {
				return "\(stub) //\n\(text)"
			}

			return text
		}

		params.onWillSendMessage = { [weak self] _ in
			self?.chatIsUnavailableView.showLoadingIndicator(needsPad: true)
		}

		return params
	}

	private var newRequestStub: String? {
		let id = self.selectedCategoryId
		
		guard let id, id != TaskTypeEnumeration.general.id else {
			return nil
		}

		var categoryName = TaskTypeEnumeration.allCases.first{ $0.id == id }?.rawValue
		categoryName ??= TaskType.taskType(id)?.name

		guard let categoryName else {
			return nil
		}

		return "New request: \(categoryName)"
	}


	private func resetSelectedCategory() {
		self.selectedCategoryId = nil
		self.recreateViewModelAndUpdateController()
	}

	private lazy var customRequestDebouncer = Debouncer(timeout: 0.1) { [weak self] in
		self?.sendCustomRequest()
	}

	private func sendCustomRequest() {
		self.controller?.showLoadingIndicator(needsPad: true)

		self.requestFormViewController?.sendRequest { [weak self] result, error in
			guard let taskID = result, error == nil else {
				self?.hideLoader(showError: error)
				return
			}

			self?.taskIdWaitingToOpenChat = taskID

			self?.shouldResetCreationViewController = true
			Notification.post(.tasksUpdateRequested)
		}
	}

	private func hideLoader(showError error: Error? = nil) {
		self.controller?.hideLoadingIndicator {
			guard let error else { return }
			if let error = error as? RequestCreationError, error != .serverResponseFailure {
				self.controller?.show(error: error.localizedDescription)
			} else {
				self.controller?.showFailureIndicator()
			}
		}
	}

	private func dismissIfRequestCreated() {
		if self.isBeingDismissedAsRequestCreated {
			return
		}

		self.isBeingDismissedAsRequestCreated = true
		
		self.dismissOverlay()
		self.recreateViewModelAndUpdateController()

		guard let id = self.selectedCategoryId, let category = TaskType.taskType(id) else {
			return
		}

		if self.isCustomRequestCategory(id) || id == TaskTypeEnumeration.general.id {
			return
		}

		let categoryName = category.localizedName(lang: "en")
		self.analyticsReporter.requestToCreateRequestFromGeneralChat(category: categoryName)
		self.analyticsReporter.didSendNewRequestIntoGeneralChat(category: "\(id) (\(categoryName))")
	}

	private func recreateViewModelAndUpdateController() {
		let viewModel = RequestCreationViewModel(
			categories: self.makeCategoriesViewModel(),
			tasks: self.tasks.map(self.taskViewModel(from:)),
			nearestTaskIndex: self.nearestTaskIndex
		)

		self.controller?.update(with: viewModel)
	}
	
	private func subscribeToNotifications() {
		Notification.onReceive(.tasksDidLoad) { [weak self] in
			self?.tasksDidLoad($0)
		}

		Notification.onReceive(.crmRequestInitiated) { [weak self] in
			self?.crmRequestInitiated($0)
		}
	}

	private static var mayCreateRestaurantRequest: Bool = true

	@objc
	private func crmRequestInitiated(_ notification: Notification) {
		if let request = notification.userInfo?["request"] as? RestaurantSDK.BookerInput {
			self.createRestaurantRequest(request)
		}
	}

	private func createRestaurantRequest(_ input: RestaurantSDK.BookerInput) {
		guard Self.mayCreateRestaurantRequest else {
			return
		}

		Self.mayCreateRestaurantRequest = false

		let controller = self.controller?.topmostPresentedOrSelf
		controller?.showWineLoader()

		DispatchQueue.global().promise {
			BookerEndpoint.shared.create(booking: input).promise
		}.done { [weak controller] _ in
			controller?.hideWineLoader()
			self.analyticsReporter.restaurantRequestCreated(0)

			AlertPresenter.alert(
				message: "booker.create.success".localized,
				actionTitle: "common.ok".localized,
				onAction: {
					DeeplinkService.shared.process(deeplink: .home)
				})
		}.catch { [weak controller] error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) booking creation failed",
					parameters: error.asDictionary
				)

			controller?.hideWineLoader()
			AlertPresenter.alert(message: "booker.create.error".localized, actionTitle: "common.ok".localized)
			DebugUtils.shared.log(sender: self, "ЭРРОР создания букинга ресторана в букере! \(error)")
		}.finally {
			Self.mayCreateRestaurantRequest = true
		}
	}

	private var taskRequestAttempts = 0

	@objc
	private func tasksDidLoad(_ notification: Notification) {
		guard let waitingTaskID = self.taskIdWaitingToOpenChat else {
			return
		}

		let newTasks = notification.userInfo?["new_tasks"] as? [Task]
		let waitingTask = newTasks?.first { $0.taskID == waitingTaskID }

		if let waitingTask {
			self.sendTaskCreatedEvent(waitingTask)

			self.controller?.hideLoadingIndicator {
				self.controller?.showSuccessIndicator()
				delay(0.25) {
					self.taskIdWaitingToOpenChat = nil
					self.openChat(for: waitingTask)
				}
			}

			return
		}

		if self.taskRequestAttempts >= 10 {
			self.hideLoader(showError: NSError())
			self.taskRequestAttempts = 0
			return
		}

		delay(1) { [weak self] in
			Notification.post(.tasksUpdateRequested)
			self?.taskRequestAttempts += 1
		}
	}

	private func sendTaskCreatedEvent(_ task: Task) {
		switch task.taskType?.type {
			case .avia:
				self.analyticsReporter.aviaRequestCreated(task.taskID)
			case .hotel:
				self.analyticsReporter.hotelRequestCreated(task.taskID)
			case .restaurants:
				break
				// ресты создаются и трекаются в другом месте
				// self.analyticsReporter.restaurantRequestCreated(task.taskID)
			default:
				break
		}
	}
	
    private func loadCachedTasks(completion: (() -> Void)?) {
        self.taskPersistenceService.retrieve().done { [weak self] tasks in
            guard let self = self,
                  let controller = self.controller else {
                return
            }

			self.set(tasks: tasks)

            controller.update(
                with: .init(
					header: self.makeHeaderViewModel(selected: .none),
                    categories: self.makeCategoriesViewModel(),
					tasks: self.tasks.map(self.taskViewModel(from:)),
					nearestTaskIndex: self.nearestTaskIndex
                )
            )
            completion?()
        }
    }
	
	func taskViewModel(from task: Task) -> ActiveTaskViewModel {
        ActiveTaskViewModel(
			taskID: task.taskID,
            title: task.title,
            subtitle: task.subtitle,
			date: task.taskDate,
			formattedDate: task.displayableDate,
			isCompleted: task.completed,
			hasReservation: task.reserved,
			image: task.taskType?.image,
			task: task
        )
    }

    func didSelectTask(at index: Int) {
		if let task = self.tasks[safe: index] {
			self.didSelectTask(task)
		}
    }
	
    private func didSelectTask(
		_ task: Task,
		isNewlyCreatedTask: Bool = false,
		shouldShowInputAccessoryView: Bool = true
	) {
		guard let controller = self.controller,
			  let assistant = task.responsible,
			  let chatParams = ChatAssembly.ChatParameters.make(for: task, assistant: assistant) else {
			return
		}

        let inputView = shouldShowInputAccessoryView ? controller.inputView : nil

		Notification.post(
			.messageInputAllowedAttachmentTypes,
			userInfo: ["attachmentTypes": MessageType.allCases]
		)

		var inputDecorations = [UIView]()
		self.activeFeedbacks.first { $0.objectId == task.taskID.description }.some { feedback in
			inputDecorations.append(
				DefaultRequestItemFeedbackView.standalone(taskId: task.taskID, insets: [0, 5, 0, 0]) { [weak self] in
					guard let self else { return }
					self.analyticsReporter.didTapOnFeedbackInChat(taskId: task.taskID, feedbackGuid: feedback.guid^)
				}
			)
		}

        let previousDraft = self.chatViewController?.removeExistingDraft()

		let chatContainerViewController = ChatAssembly.makeChatContainerViewController(
			with: chatParams,
			presentationViewController: controller,
            inputAccessoryView: inputView,
			inputDecorationViews: inputDecorations,
            overlayView: self.chatOverlayView
		)

		// Temporary draft transfer operations among chats
		if isNewlyCreatedTask {
			self.chatContainerViewController = chatContainerViewController
			self.chatViewController?.updateInput(with: previousDraft)
			self.chatViewController?.sendDraftWhenAppeared()
		}

		self.chatOverlayView.isHidden = true

		controller.displayChild(viewController: chatContainerViewController)
	}
	
	private func makeHeaderViewModel(selected: TaskAccessoryHeaderViewModel.Selected? = nil) -> TaskAccessoryHeaderViewModel {
		let selected = selected ?? (self.numberOfTasks > 0 ? .existing : .new)
		let existingTitle = "\("createTask.in.progress".localized) (\(self.numberOfTasks))"
		return TaskAccessoryHeaderViewModel (
			title: "",
			existingButton: .init(title: existingTitle, imageName: nil, onTap: { [weak self] in
				self?.existingButtonPressed()
			}),
			newButton: .init(title: "createTask.new".localized, imageName: "plus_icon", onTap: { [weak self] in
				self?.newButtonPressed()
			}),
			selected: selected
		)
	}

	private func makeCategoriesViewModel() -> RequestCreationCategoriesViewModel {
		let topCategoriesIds = TaskType.taskTypesFor(row: 1) ??
		[
			TaskTypeEnumeration.hotel,
			TaskTypeEnumeration.avia,
			TaskTypeEnumeration.vipLounge,
			TaskTypeEnumeration.transfer,
			TaskTypeEnumeration.visa,
			TaskTypeEnumeration.carRental
		].map(\.id)

		let bottomCategoriesIds = TaskType.taskTypesFor(row: 2) ??
		[
			TaskTypeEnumeration.restaurants,
			TaskTypeEnumeration.eventsList,
			TaskTypeEnumeration.tickets,
			// TaskTypeEnumeration.alcohol,
			TaskTypeEnumeration.flowers,
		].map(\.id)

		let topCategories = topCategoriesIds.compactMap{ TaskType.taskType($0) }
		let bottomCategories = bottomCategoriesIds.compactMap{ TaskType.taskType($0) }

        let topRows: [RequestCreationCategoriesViewModel.Button] = topCategories.map {
            .init(id: $0.id, image: $0.image, title: $0.localizedName)
        }
        
        let bottomRows: [RequestCreationCategoriesViewModel.Button] = bottomCategories.map {
            .init(id: $0.id, image: $0.image, title: $0.localizedName)
        }
        
        return RequestCreationCategoriesViewModel(
            topRow: topRows,
            bottomRow: bottomRows,
            selectedId: self.selectedCategoryId
		) { [weak self] id in
				guard let self else { return }
				self.selectedCategoryId = id
				let dismissInputAccessory = self.isCustomRequestCategory(id)
				self.showCreationForm(forCategoryId: id, dismissInputAccessory: dismissInputAccessory)
            }
    }

    private func newButtonPressed() {
        if let index = self.selectedCategoryId {
            self.presentOverlay(for: index)
        }
        self.controller?.update(
            with: .init(
				header: self.makeHeaderViewModel(selected: .new),
				tasks: self.tasks.map(self.taskViewModel(from:)),
				nearestTaskIndex: self.nearestTaskIndex
            )
        )
    }

    private func existingButtonPressed() {
        self.dismissOverlay()
        self.controller?.update(
            with: .init(
				header: self.makeHeaderViewModel(selected: .existing),
				tasks: self.tasks.map(self.taskViewModel(from:)),
				nearestTaskIndex: self.nearestTaskIndex
            )
        )
    }

	private func showCreationForm(
		forCategoryId id: Int,
		userInfo: [String: String]? = nil,
		dismissInputAccessory: Bool = true
	) {
		if id == TaskTypeEnumeration.restaurants.id {
			self.showRestaurantsForm(userInfo: userInfo)
			return
		}

		self.selectedCategoryId = id

        self.dismissOverlay()
        self.controller?.update(
            with: .init(
				header: makeHeaderViewModel(selected: .new),
                categories: makeCategoriesViewModel(),
				tasks: self.tasks.map(self.taskViewModel(from:)),
				nearestTaskIndex: self.nearestTaskIndex
            )
        )
		self.presentOverlay(for: id, dismissInputAccessory: dismissInputAccessory)
    }

	private func webForm(_ name: String) -> RequestFormViewController? {
		let servicesData = self.servicesEndpoint.latestServices?.data
		let service = servicesData?.first {
			$0.name?.lowercased().contains(name) ?? false
		}

		var url = service?.url

		if url == nil {
			if name == "wine" {
				url = Config.wineEndpoint
			}
			if name == "flowers" {
				url = Config.flowersEndpoint
			}
		}

		guard var url = url?.replacing(regex: "(\\/)*\\?.*$", with: "") else {
			return nil
		}

		let token = LocalAuthService.shared.token?.accessToken ?? ""
		let clientId = LocalAuthService.shared.user?.username ?? ""
		let prefix = Config.appUrlSchemePrefix

		url.append("?token=\(token)&access_token=\(token)&client_id=\(clientId)&prefix=\(prefix)")

		guard let url = URL(string: url) else {
			return nil
		}

		let viewController = SFSafariViewController(url: url)
		viewController.preferredControlTintColor = Palette.shared.brandPrimary.rawValue
		return viewController
	}

    private func showRestaurantsForm(userInfo: [String: String]? = nil) {
        guard let userID = Int(LocalAuthService.shared.user?.username ?? ""),
              let token = LocalAuthService.shared.token?.accessToken else {
            return
        }
        
        RestaurantSDK.MAY_LOG_IN_PRINT = Config.isDebugEnabled
        RestaurantSDK.acceptExternalLogger(DebugUtils.shared)
        
        let credentials = RestaurantSDK.AuthorizationData(
            userID: userID,
            token: token,
            hostessToken: token
        )
        
		let config = RestaurantSDK.HomeAssemblyConfig(
			credentials: credentials,
			primePassBasePath: Config.primePassBasePath,
			primePassHostessBasePath: Config.primePassHostessBasePath,
			navigatorBasePath: Config.navigatorBasePath,
			parameters: userInfo
		)
        
        let restaurantsForm = RestaurantSDK.HomeAssembly(config: config).makeModule()
        restaurantsForm.modalPresentationStyle = .fullScreen
        
        (restaurantsForm as? RestaurantSDK.HomeViewController)?.onDismiss = { [weak self] in
            let controller = self?.controller?.presentingViewController ?? self?.controller
            controller?.dismiss(animated: true)
        }
        
        self.analyticsReporter.willShowRestaurantsForm()
		self.presentOrWaitSelfDidAppear(restaurantsForm)
    }

	private func presentOrWaitSelfDidAppear(_ targetController: UIViewController) {
		guard let controller = self.controller else {
			UIViewController.topmostPresented?.present(targetController, animated: true)
			return
		}

		if controller.view.window == nil {
			self.didAppearWaitingBlocks.append {
				controller.present(targetController, animated: true)
			}
			return
		}

		controller.present(targetController, animated: true)
	}

	private var customRequestCategories: [TaskTypeEnumeration] {
		var customRequestTypes: [TaskTypeEnumeration] = [.hotel, .flowers, .restaurants]

		if UserDefaults[bool: "vipLoungeEnabled"] {
			customRequestTypes.append(.vipLounge)
		}

		if UserDefaults[bool: "aviaEnabled"] {
			customRequestTypes.append(.avia)
		}

		if UserDefaults[bool: "wineEnabled"] {
			customRequestTypes.append(.alcohol)
		}

		return customRequestTypes
	}

	private func isCustomRequestCategory(_ category: Int?) -> Bool {
		guard let category else {
			return false
		}
		let isCustomRequestForm = self.customRequestCategories.contains { $0.id == category }
		return isCustomRequestForm
	}

	private func makeChatIsUnavailableViewHidden(_ isHidden: Bool) {
		self.chatIsUnavailableView.isHidden = isHidden
		self.chatOverlayView.isUserInteractionEnabled = !isHidden
	}
    
    private func presentOverlay(for category: Int, dismissInputAccessory: Bool = true) {
		self.chatOverlayView.isHidden = false

		self.chatContainerViewController?.isHeaderViewHidden = true
		self.selectedCategoryId = category

		var attachmentTypes = MessageType.allCases

		if self.isCustomRequestCategory(category) {
			attachmentTypes = [MessageType.image, MessageType.video]
			self.chatViewController?.isVoiceButtonHidden = true
		}

		let notification = Notification(
			name: .messageInputAllowedAttachmentTypes,
			object: nil,
			userInfo: ["attachmentTypes": attachmentTypes]
		)

		NotificationCenter.default.post(notification)

		if dismissInputAccessory {
			self.chatViewController?.setInputAccessory(nil)
		}

		let isCustomRequestForm = self.isCustomRequestCategory(category)

		self.chatContainerViewController?.isHeaderViewHidden = isCustomRequestForm

		guard isCustomRequestForm else {
			self.makeChatIsUnavailableViewHidden(true)
			return
		}

		var customRequestViewController: RequestFormViewController?
		if category == TaskTypeEnumeration.hotel.id {
            self.analyticsReporter.willShowHotelForm()
            customRequestViewController = self.hotelBookingViewController
		}
        else if category == TaskTypeEnumeration.avia.id {
			self.aviaBookingViewController = AviaFormAssembly().make()
            self.analyticsReporter.willShowAviaForm()
            customRequestViewController = self.aviaBookingViewController!
		}
        else if category == TaskTypeEnumeration.alcohol.id, let webForm = self.webForm("wine") {
			customRequestViewController = webForm
			self.chatViewController?.isWholeInputControlHidden = true
		}
        else if category == TaskTypeEnumeration.flowers.id, let webForm = self.webForm("flowers") {
			customRequestViewController = webForm
			self.chatViewController?.isWholeInputControlHidden = true
		}
        else if category == TaskTypeEnumeration.vipLounge.id, UserDefaults[bool: "vipLoungeEnabled"]  {
            self.analyticsReporter.didTapOpenVipLoungeForm()
            self.vipLoungeViewController = VIPLoungeFormAssembly().make()
            if let vipLoungeVC = self.vipLoungeViewController {
                customRequestViewController = vipLoungeVC
            }
        }
    
		guard let customRequestViewController,
			  let customRequestView = customRequestViewController.view else {
			self.makeChatIsUnavailableViewHidden(true)
            return
        }

		Notification.post(.messageInputShouldHideKeyboard, userInfo: ["animated": true])

		self.makeChatIsUnavailableViewHidden(false)

		var viewForKeyboardTracker = customRequestView
		if let aviaViewController = customRequestViewController as? AviaFormViewControllerProtocol {
			viewForKeyboardTracker = aviaViewController.aviaFormView
		}

        self.keyboardHeightTracker = .init(view: viewForKeyboardTracker) { _ in }
        self.keyboardHeightTracker?.onWillShowKeyboard = { [weak self] in
			if self?.aviaBookingViewController?.presentedViewController != nil {
				return
			}
            self?.aviaBookingViewController?.shouldPinFormToTop(true)
            
        }
        self.keyboardHeightTracker?.onWillHideKeyboard = { [weak self] in
			if self?.aviaBookingViewController?.presentedViewController != nil {
				return
			}
            self?.aviaBookingViewController?.shouldPinFormToTop(false)
        }

		self.chatOverlayView.backgroundColorThemed = customRequestView.backgroundColorThemed
        customRequestView.backgroundColorThemed = Palette.shared.clear

		let parent = self.chatOverlayView.viewController
        customRequestViewController.willMove(toParent: parent)
        parent?.addChild(customRequestViewController)
		self.chatOverlayView.addSubview(customRequestView)
        customRequestViewController.didMove(toParent: parent)
        customRequestView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.requestFormViewController = customRequestViewController
    }

	private func openChat(for task: Task) {
		self.dismissOverlay()

		self.didSelectTask(
			task,
			isNewlyCreatedTask: true,
			shouldShowInputAccessoryView: false
		)
    }
    
    private func dismissOverlay() {
        self.chatOverlayView.isHidden = true
		self.chatContainerViewController?.isHeaderViewHidden = false

		let notification = Notification(
			name: .messageInputAllowedAttachmentTypes,
			object: nil,
			userInfo: ["attachmentTypes": MessageType.allCases]
		)

		NotificationCenter.default.post(notification)
        
        guard let viewController = self.requestFormViewController,
              let view = viewController.view else {
            return
        }

		self.resetSelectedCategory()

        viewController.willMove(toParent: nil)
        view.removeFromSuperview()
        viewController.didMove(toParent: nil)

		if self.shouldResetCreationViewController {
			self.shouldResetCreationViewController = false
			self.requestFormViewController?.reset()
		}
        self.requestFormViewController = nil
    }
}

private extension RequestCreationPresenter {
	func set(tasks: [Task]) {
		self.tasks = tasks.sorted { task1, task2 in
			let date1 = task1.taskDate
			let date2 = task2.taskDate

			if date1 == nil {
				return true
			}

			if date2 == nil {
				return true
			}

			return date2! > date1!
		}

		let now = Date()

		self.nearestTaskIndex = self.tasks.firstIndex { task in
			guard let taskDate = task.taskDate else {
				return false
			}
			return taskDate >= now
		}
	}
}
// swiftlint:enable trailing_whitespace

extension UIView {
    var viewController: UIViewController? {
        sequence(first: self) { $0.next }
            .first(where: { $0 is UIViewController })
            .flatMap { $0 as? UIViewController }
    }
}

extension SFSafariViewController: RequestFormViewController {
	func sendRequest(completion: @escaping (Int?, Error?) -> Void) {
		completion(nil, NSError())
	}

	func reset() { }
}

// swiftlint:enable file_length
