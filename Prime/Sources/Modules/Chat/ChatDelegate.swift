import UIKit
import ChatSDK

// MARK: - Wrapper for ChatDelegate

final class ChatDelegate: ChatDelegateProtocol {
	var viewControllerProvider: (() -> UIViewController?)?

	private let onDidLoadInitialMessages: (() -> Void)?
	private let onTextViewEditingStatusUpdate: ((Bool) -> Void)?
	private let onAttachementsStatusUpdate: ((Int) -> Void)?
	private let onDecideIfMaySendMessage: ((MessagePreview?, @escaping ((Bool) -> Void)) -> Void)?
	private let onWillSendMessage: ((MessagePreview?) -> Void)?
	private let onMessageSend: ((MessagePreview, Bool) -> Void)?
	private let onMessageSending: ((MessagePreview) -> Void)?
	private let onModifyTextBeforeSending: ((String) -> String)?
	private let onDraftUpdated: ((ChatEditingEvent) -> Void)?

	var shouldShowSafeAreaView: Bool { true }

	init(
		onTextViewEditingStatusUpdate: ((Bool) -> Void)? = nil,
		onAttachementsStatusUpdate: ((Int) -> Void)? = nil,
		onDidLoadInitialMessages: (() -> Void)?,
		onDecideIfMaySendMessage: ((MessagePreview?, @escaping ((Bool) -> Void)) -> Void)?,
		onModifyTextBeforeSending: ((String) -> String)? = nil,
		onWillSendMessage: ((MessagePreview?) -> Void)? = nil,
		onMessageSend: ((MessagePreview, Bool) -> Void)? = nil,
		onMessageSending: ((MessagePreview) -> Void)? = nil,
		onDraftUpdated: ((ChatEditingEvent) -> Void)? = nil
	) {
		self.onTextViewEditingStatusUpdate = onTextViewEditingStatusUpdate
		self.onAttachementsStatusUpdate = onAttachementsStatusUpdate
		self.onDidLoadInitialMessages = onDidLoadInitialMessages
		self.onDecideIfMaySendMessage = onDecideIfMaySendMessage
		self.onModifyTextBeforeSending = onModifyTextBeforeSending
		self.onWillSendMessage = onWillSendMessage
		self.onMessageSend = onMessageSend
		self.onMessageSending = onMessageSending
		self.onDraftUpdated = onDraftUpdated
	}

	func requestPhoneCall(number: String) {
		guard let url = URL(string: "tel://\(number)"),
			  UIApplication.shared.canOpenURL(url) else {
			return
		}

		UIApplication.shared.open(url)
	}

	func requestPresentation(for controller: UIViewController, completion: (() -> Void)?) {
		self.viewControllerProvider?()?
			.topmostPresentedOrSelf
			.present(controller, animated: true, completion: completion)
	}

	func didChatControllerStatusUpdate(with status: ChatControllerStatus) { }

	func didTextViewEditingStatusUpdate(with value: Bool) {
		self.onTextViewEditingStatusUpdate?(value)
	}

	func didAttachmentsUpdate(_ update: AttachmentsUpdate, totalCount: Int) { }

	func didVoiceMessageStatusUpdate(with status: VoiceMessageStatus) { }

	func willSendMessage(_ preview: ChatSDK.MessagePreview?) {
		self.onWillSendMessage?(preview)
	}

	func didMessageSendingStatusUpdate(with status: MessageSendingStatus, preview: MessagePreview) {
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			switch status {
				case .error:
					self.onMessageSend?(preview, false)
				case .success:
					Notification.post(.chatDidSendMessage, userInfo: ["preview": preview])
					self.onMessageSend?(preview, true)
				case .inProgress:
					self.onMessageSending?(preview)
			}
		}
	}

	func didChannelAttachementsUpdate(_ update: AttachmentsUpdate, totalCount: Int) {
		self.onAttachementsStatusUpdate?(totalCount)
	}

	func modifyTextBeforeSending(_ text: String) -> String {
		self.onModifyTextBeforeSending?(text) ?? text
	}

	func decideIfMaySendMessage(_ message: MessagePreview, _ asyncDecisionBlock: @escaping (Bool) -> Void) {
		guard let externalLogic = self.onDecideIfMaySendMessage else {
			asyncDecisionBlock(true)
			return
		}

		externalLogic(message, asyncDecisionBlock)
	}

	func didLoadInitialMessages() {
		self.onDidLoadInitialMessages?()
	}

	func didUpdateDraft(event: ChatEditingEvent) {
		self.onDraftUpdated?(event)
	}
}
