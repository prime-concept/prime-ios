import UIKit
import ChatSDK

protocol RequestListDisplayableModel {
	var id: String { get }
}

struct RequestListItemViewModel: RequestListDisplayableModel {
	let id: String
    let headerViewModel: ActiveTaskViewModel
    let lastMessageViewModel: RequestItemLastMessageViewModel?
	let feedbackViewModel: RequestItemFeedbackViewModel?
	
    let unreadMessageCount: Int?
	let orders: [HomePayItemViewModel]
	let promoCategories: [PromoCategoryViewModel]

	let roundsCorners: Bool

	init(
		task: Task,
		showsLatestMessage: Bool = true,
		showsPromoCategories: Bool = true,
		showsFeedback: Bool = false,
		taskTypeImageLeading: CGFloat = 9,
		taskTypeImageSize: CGSize = CGSize(width: 36, height: 36),
		routesToTaskDetails: Bool = false,
        promoCategories: [Int: [Int]] = [:],
		roundsCorners: Bool = true
	) {
		self.id = "\(task.taskID)"

		self.headerViewModel = ActiveTaskViewModel(
			taskID: task.taskID,
			title: task.title?.trim(),
			subtitle: task.subtitle?.trim(),
			date: task.taskDate,
			formattedDate: task.displayableDate,
			isCompleted: task.completed,
			hasReservation: task.reserved,
			image: task.taskType?.image,
			imageLeading: taskTypeImageLeading,
			imageSize: taskTypeImageSize,
			routesToTaskDetails: routesToTaskDetails,
			task: task
		)

		self.roundsCorners = roundsCorners
		if showsPromoCategories {
			self.promoCategories = Self.promoCategories(for: task, promoCategories: promoCategories)
		} else {
			self.promoCategories = []
		}

		var latestMessageViewModel: RequestItemLastMessageViewModel? = nil

		if showsLatestMessage {
			let models: [MessageComparable?] = [task.lastChatMessage, task.latestDraft]
			var latestMessage: MessageComparable?

			if let draft = models.first(where: { $0?.status == .draft }) {
				latestMessage = draft
			} else {
				latestMessage = models.compactMap{ $0 }.sorted{ $0.timestamp > $1.timestamp }.first
			}

			if let message = latestMessage as? Message,
			   var viewModel = RequestItemLastMessageViewModel(
				with: message,
				unreadCount: task.unreadCount,
				messenger: message.source
			   ) {
				Self.updateIcons(on: &viewModel, source: message.source)
				latestMessageViewModel = viewModel
			}
		}

		if showsFeedback {
			self.feedbackViewModel = RequestItemFeedbackViewModel(
				title: "feedback.please.rate1".localized,
				rating: 0,
				taskCompleted: task.completed
			)
		} else {
			self.feedbackViewModel = nil
		}
		
		self.lastMessageViewModel = latestMessageViewModel
		self.unreadMessageCount = latestMessageViewModel?.unreadCount
		self.orders = task.ordersWaitingForPayment
			.map {
				HomePayItemViewModel(order: $0, taskIcon: task.taskType?.image)
			}
	}

    private static func promoCategories(for task: Task, promoCategories: [Int: [Int]]) -> [PromoCategoryViewModel] {
		guard UserDefaults[bool: "promoCategoriesEnabled"] else {
			return []
		}

		guard let taskId = task.taskType?.id else { return [] }

		let promoCategoriesIds = promoCategories[taskId] ?? []
		let promoCategoriesTypes = promoCategoriesIds.compactMap { id in
			TaskTypeEnumeration(id: id)
		}

		let viewModels = promoCategoriesTypes.map {
			PromoCategoryViewModel(
				id: $0.id,
				title: $0.correctName,
				image: $0.defaultImage
			)
		}

		return viewModels
	}

	private static func updateIcons(on viewModel: inout RequestItemLastMessageViewModel, source: String?) {
		func updateStatusIcon() {
			guard viewModel.status != .draft, !viewModel.isIncome else {
				viewModel.statusImage = nil
				return
			}

			switch viewModel.status {
				case .sending, .new:
					viewModel.statusImage = UIImage(named: "channel_sending")
				case .failed, .unknown:
					viewModel.statusImage = UIImage(named: "channel_failed")
				case .seen:
					viewModel.statusImage = UIImage(named: "channel_seen")
				default:
					viewModel.statusImage = UIImage(named: "channel_sent")
			}
		}

		func updateMessengerIcon() {
			if viewModel.isIncome {
				viewModel.messengerIcon = nil
				return
			}

			switch source {
				case "SMS":
					viewModel.messengerIcon = UIImage(named: "other_messenger_sms")
				case "EMAIL":
					viewModel.messengerIcon = UIImage(named: "other_messenger_email")
				case "TELEGRAM":
					viewModel.messengerIcon = UIImage(named: "other_messenger_telegram")
				case "WHATSAPP":
					viewModel.messengerIcon = UIImage(named: "other_messenger_whatsapp")
				default:
					viewModel.messengerIcon = nil
			}
		}

		updateStatusIcon()
		updateMessengerIcon()
	}
}

extension RequestItemLastMessageViewModel {
	init?(with lastMessage: Message, unreadCount: Int, messenger: String? = nil) {
		let date = lastMessage.timestamp
		guard let dateTime = PrimeDateFormatter.messageDateTimeString(from: date) else {
			return nil
		}

		var text = "message.preview.unsupported.message".localized
		var icon: UIImage? = UIImage(named: "content_docs")
		var preview: UIImage? = nil

		switch lastMessage.type {
			case .text:
				text = lastMessage.content
				icon = nil
				preview = nil
			case .image:
				text = "message.preview.image".localized
				icon = UIImage(named: "content_docs")
				preview = nil
			case .voiceMessage:
				text = "message.preview.voice.message".localized
				icon = UIImage(named: "content_voice")
				preview = nil
			case .video:
				text = "message.preview.video".localized
				icon = UIImage(named: "content_docs")
				preview = nil
			case .location:
				text = "message.preview.location".localized
				icon = UIImage(named: "content_geo")
				preview = nil
			case .contact:
				text = lastMessage.displayName.isEmpty
					   ? "message.preview.contact".localized
					   : lastMessage.displayName
				icon = UIImage(named: "content_contact")
				preview = nil
			case .doc:
				text = lastMessage.displayName.isEmpty
					? "message.preview.document".localized
					: lastMessage.displayName
				icon = UIImage(named: "content_docs")
				preview = nil
			default:
				break
		}

		let isIncome = lastMessage.clientId.lowercased().hasPrefix("u")

		self.init(
			isIncome: isIncome,
			text: text,
			preview: preview,
			icon: icon,
			dateTime: dateTime,
			unreadCount: unreadCount,
			status: lastMessage.status
		)
	}
}

private protocol MessageComparable {
	var timestamp: Date { get }
	var status: MessageStatus { get }
}

extension Message: MessageComparable {}

extension ChannelPreview: MessageComparable {
	var timestamp: Date {
		self.lastMessagePreview?.timestamp ?? Date(timeIntervalSince1970: 0)
	}

	var status: MessageStatus {
		self.lastMessagePreview?.status ?? .unknown
	}
}
