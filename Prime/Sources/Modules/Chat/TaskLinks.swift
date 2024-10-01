import UIKit
import ChatSDK

// Stub for task links
final class TaskLinkContentView: UIView, MessageContentViewProtocol {

	var guid: String?

	var shouldAddBorder: Bool { false }

	var shouldAddInfoViewPad: Bool { false }

	var openContent: ((@escaping MessageContentOpeningCompletion) -> Void)?

	init() {
		super.init(frame: .zero)
		self.backgroundColorThemed = Palette.shared.systemLightGray
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func reset() { }

	func currentContentWidth(constrainedBy width: CGFloat, infoViewArea: CGSize) -> CGFloat { width }

	func updateInfoViewFrame(_ frame: CGRect) { }

	func setLongPressHandler(_ handler: @escaping () -> Void) -> Bool { false }
}

struct TaskLinkContent: MessageContent {
	static let messageType = MessageType.taskLink

	var replyPreview: String { "chat.reply.preview.task.link".localized }

	var rawContent: String { self.content }

	var messageGUID: String?
	private let content: String

	init(messageGUID: String? = nil, content: String) {
		self.messageGUID = messageGUID
		self.content = content
	}

	static func decode(from decoder: Decoder) throws -> Self {
		TaskLinkContent(content: "")
	}

	func encode(to encoder: Encoder) throws { }
}

final class TaskLinkContentRenderer: ContentRenderer {
	static var messageContentType: MessageContent.Type = TaskLinkContent.self
	static var messageModelType: MessageModel.Type { MessageContainerModel<TaskLinkContentView>.self }

	private let actions: ContentRendererActions

	init(actions: ContentRendererActions) {
		self.actions = actions
	}

	static func make(
		for content: MessageContent,
		contentMeta: ContentMeta,
		actions: ContentRendererActions,
		dependencies: ContentRendererDependencies
	) -> ContentRenderer {
		Self(actions: actions)
	}

	func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
		MessageContainerModel<TaskLinkContentView>(
			uid: uid,
			meta: meta,
			contentControlValue: -1,
			shouldCalculateHeightOnMainThread: false,
			actions: self.actions,
			contentConfigurator: { _ in },
			heightCalculator: { _, _ in 44.0 }
		)
	}

	func preview() -> MessagePreview.ProcessedContent? { nil }

	func showFullContent() { }
}
