import ChatSDK
import UIKit

extension Notification.Name {
	static let chatDidSendMessage = Notification.Name("chatDidSendMessage")
}

final class ChatAssembly {
	struct ChatParameters {
		let chatToken: String
		let channelID: String
		let channelName: String
		let clientID: String
		var messageGuidToOpen: String?
		var messageTypesToIgnore: [MessageType] = [.taskLink]
		var preinstalledText: String? = nil
		var mayShowKeyboardWhenAppeared: Bool = true
        var activeFeedbacks: [ActiveFeedback] = []

		var task: Task? = nil
		let assistant: Assistant
		var onDidLoadInitialMessages: (() -> Void)? = nil

		// Этот колбэк вызывается для каждого вложения в рамках сообщения. Текст это тоже вложение.
		// Но сперва он вызывается с превью == MessagePreview.outcomeStub,
		// чтобы решить, а посылать ли сообщение вообще.
		// То есть вызовов будет на 1 больше, чем вложений.
		var onDecideIfMaySendMessage: ((MessagePreview?, @escaping ((Bool) -> Void)) -> Void)?
		var onModifyTextBeforeSending: ((String) -> String)? = nil
		var onWillSendMessage: ((MessagePreview?) -> Void)? = nil
		var onMessageSending: ((MessagePreview) -> Void)? = nil
		var onMessageSend: ((MessagePreview, Bool) -> Void)? = nil
		var onDraftUpdated: ((ChatEditingEvent) -> Void)? = nil
        var onAddNewRequest: (() -> Void) = {
            DeeplinkService.shared.process(deeplink: .createTask(.general))
        }

		static func make(
			for task: Task,
			chatToken: String? = LocalAuthService.shared.token?.accessToken,
			channelName: String = "Чат",
			assistant: Assistant,
            activeFeedbacks: [ActiveFeedback] = []
		) -> Self? {
			guard let chatToken, let chatID = task.chatID else {
				return nil
			}

			return Self(
				chatToken: chatToken,
				channelID: "T\(chatID)",
				channelName: channelName,
				clientID: "C\(task.customerID)",
                activeFeedbacks: activeFeedbacks, 
                task: task,
                assistant: assistant
			)
		}
	}

	enum ChatStyle {
		// Обычные чаты
		case `default`
		// Чат, встроенный в экран списка запросов
		case requestsCustom

		var theme: ChatSDK.Theme {
			switch self {
			case .default:
				return ChatSDK.Theme(
					palette: ChatPalette(),
					imageSet: ChatImageSet(),
					styleProvider: ChatStyleProvider(),
					fontProvider: ChatFontProvider(),
					layoutProvider: ChatLayoutProvider()
				)
			case .requestsCustom:
				return ChatSDK.Theme(
					palette: ChatPalette(),
					imageSet: ChatImageSet(),
					styleProvider: ChatStyleProvider(),
					fontProvider: ChatFontProvider(),
					layoutProvider: ChatRequestsCustomLayoutProvider()
				)
			}
		}
	}
	
	static func makeChat(
		chatToken: String,
		clientID: String
	) -> ChatSDK.Assembly {
		let chatConfiguration = Configuration(
			chatBaseURL: Config.chatBaseURL,
			storageBaseURL: Config.chatStorageURL,
			contentRenderers: [TaskLinkContentRenderer.self],
			initialTheme: ChatStyle.default.theme,
            featureFlags: Configuration.FeatureFlags.all(except: Config.voiceMessagesEnabled ? [] : .canSendVoiceMessage),
			clientAppID: Config.chatClientAppID
		)

		return ChatSDK.Assembly(
			clientID: clientID,
			accessToken: chatToken,
			configuration: chatConfiguration
		)
	}

    static func makeChatContainerViewController(
        with parameters: ChatParameters,
        presentationViewController: UIViewController? = nil,
		inputAccessoryView: UIView? = nil,
		inputDecorationViews: [UIView] = [],
		overlayView: UIView? = nil,
        isReadOnly: Bool = false,
        onDismiss: @escaping () -> Void = {}
    ) -> ChatContainerViewController {

        let chatConfiguration = Configuration(
            chatBaseURL: Config.chatBaseURL,
            storageBaseURL: Config.chatStorageURL,
            contentRenderers: [TaskLinkContentRenderer.self],
            initialTheme: ChatStyle.default.theme,
            featureFlags: Configuration.FeatureFlags.all(except: Config.voiceMessagesEnabled ? [] : .canSendVoiceMessage),
            clientAppID: Config.chatClientAppID
        )

        let delegate = ChatDelegate(
			onDidLoadInitialMessages: parameters.onDidLoadInitialMessages,
			onDecideIfMaySendMessage: parameters.onDecideIfMaySendMessage,
			onModifyTextBeforeSending: parameters.onModifyTextBeforeSending,
			onWillSendMessage: parameters.onWillSendMessage,
			onMessageSend: parameters.onMessageSend,
			onMessageSending: parameters.onMessageSending,
			onDraftUpdated: parameters.onDraftUpdated
		)

        let assembly = ChatSDK.Assembly(
            clientID: parameters.clientID,
            accessToken: parameters.chatToken,
            configuration: chatConfiguration
        )

        let chatViewController = assembly.makeChatViewController(
            channelID: parameters.channelID,
            chatDelegate: delegate,
            messageTypesToIgnore: parameters.messageTypesToIgnore,
            preinstalledText: parameters.preinstalledText,
            messageGuidToOpen: parameters.messageGuidToOpen
        )

        let chatContainerViewController = ChatContainerViewController(
            assistant: parameters.assistant,
            task: parameters.task, 
            chatViewController: chatViewController,
            onPhoneTap: { [weak delegate] number in
                delegate?.requestPhoneCall(number: number)
            },
            onDismiss: onDismiss
        )
        
		let parentViewController = presentationViewController ?? chatContainerViewController
		delegate.viewControllerProvider = { [weak parentViewController] in
			parentViewController ?? UIViewController.topmostPresented
		}

		let taskCompleted = parameters.task?.completed ?? false
		
        overlayView.some {
            chatViewController.setOverlay($0)
        }

		if let inputAccessoryView, isReadOnly == false {
			chatViewController.setInputAccessory(inputAccessoryView) 
            
			if !taskCompleted, parameters.mayShowKeyboardWhenAppeared {
				chatViewController.showKeyboardWhenAppeared()
			}
		} else {
			chatViewController.setInputAccessory(UIView())
		}

		inputDecorationViews.forEach { view in
			chatViewController.addInputDecoration(view)
		}

        chatViewController.isWholeInputControlHidden = isReadOnly || taskCompleted
        
        if taskCompleted {
            let addNewRequestButton = CustomPillViewContainer()
            
            let plusImage = UIImage(named: "avia_plus")
            let titleText = "create.request.new".localized
            
            addNewRequestButton.setup(image: plusImage, title: titleText, action: parameters.onAddNewRequest)
            chatViewController.addBottomView(addNewRequestButton)

			chatContainerViewController.preFirstAppear = {
                if let taskID = parameters.task?.taskID, 
                    parameters.activeFeedbacks.first(where: { $0.objectId == taskID.description }) != nil {
                    
					showFeedback(for: taskID)
				}
			}
        }
    
        chatContainerViewController.setContent(chatViewController)
        return chatContainerViewController
    }
}

// MARK: - Feedback Rating

private func showFeedback(for taskID: Int) {
	let window = PrimeWindow()
	let feedbackContainer = CompletedTaskFeedbackContainer()

	feedbackContainer.didCloseContainer = {
		window.isHidden = true
		feedbackContainer.removeFromSuperview()
	}

	feedbackContainer.didTapOnStars = { rating in
		let userInfo = ["taskId": taskID, "rating": rating]
		Notification.post(.didTapOnFeedback, userInfo: userInfo as [AnyHashable : Any])

		feedbackContainer.closeBottomSheet()
	}

	window.addSubview(feedbackContainer)
	feedbackContainer.make(.edges, .equalToSuperview)
	feedbackContainer.alpha = 0
	UIView.animate(withDuration: 0.3) {
		feedbackContainer.alpha = 1
	}

	window.makeKeyAndVisible()
}
