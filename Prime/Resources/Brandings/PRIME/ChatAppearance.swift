import UIKit
import ChatSDK

final class ChatPalette: ThemePalette {
    var bubbleOutcomeBackground: UIColor { Palette.shared.brandPrimary.rawValue }
    var bubbleOutcomeText: UIColor { Palette.shared.gray5.rawValue }
    var bubbleOutcomeInfoTime: UIColor { Palette.shared.gray5.withAlphaComponent(0.9).rawValue }

    var bubbleIncomeBorder: UIColor { Palette.shared.gray3.rawValue }
    var bubbleOutcomeBorder: UIColor { Palette.shared.clear.rawValue }

    var bubbleIncomeBackground: UIColor { Palette.shared.gray5.rawValue }
    var bubbleIncomeText: UIColor { Palette.shared.gray0.rawValue }
    var bubbleIncomeInfoTime: UIColor { Palette.shared.gray1.rawValue }

    var bubbleBorder: UIColor { Palette.shared.gray3.rawValue }
    var bubbleInfoPadBackground: UIColor { Palette.shared.gray0.withAlphaComponent(0.3).rawValue }
    var bubbleInfoPadText: UIColor { Palette.shared.gray5.rawValue }

	var timeSeparatorText: UIColor { Palette.shared.gray5.rawValue }
	var timeSeparatorBackground: UIColor { Palette.shared.gray0.withAlphaComponent(0.4).rawValue }

    var voiceMessageRecordingCircleTint: UIColor { Palette.shared.gray5.rawValue }
    var voiceMessageRecordingCircleBackground: UIColor { Palette.shared.brandPrimary.withAlphaComponent(0.5).rawValue }
    var voiceMessageRecordingTime: UIColor { Palette.shared.gray0.rawValue }
    var voiceMessageRecordingIndicator: UIColor { Palette.shared.danger.rawValue }
    var voiceMessageRecordingDismissTitle: UIColor { Palette.shared.gray1.rawValue }
    var voiceMessageRecordingDismissIndicator: UIColor { Palette.shared.gray1.rawValue }

    var senderButton: UIColor { Palette.shared.brandSecondary.rawValue }
    var senderBorderShadow: UIColor { Palette.shared.gray3.rawValue }
    var senderBackground: UIColor { Palette.shared.gray5.rawValue }
    var senderPlaceholderColor: UIColor { Palette.shared.gray1.rawValue }
    var senderTextColor: UIColor { Palette.shared.gray0.rawValue }

    var contactIconIncomeBackground: UIColor { Palette.shared.brandPrimary.rawValue }
    var contactIconOutcomeBackground: UIColor { Palette.shared.gray5.withAlphaComponent(0.25).rawValue }
    var contactIcon: UIColor { Palette.shared.gray5.rawValue }
    var contactIncomeTitle: UIColor { Palette.shared.gray0.rawValue }
    var contactOutcomeTitle: UIColor { Palette.shared.gray5.rawValue }
    var contactIncomePhone: UIColor { Palette.shared.gray1.rawValue }
    var contactOutcomePhone: UIColor { Palette.shared.gray5.rawValue }

    var locationPickBackground: UIColor { Palette.shared.gray5.rawValue }
    var locationPickTitle: UIColor { Palette.shared.gray0.rawValue }
    var locationPickSubtitle: UIColor { Palette.shared.gray1.rawValue }
    var locationControlBackground: UIColor { Palette.shared.gray3.withAlphaComponent(0.5).rawValue }
    var locationControlButton: UIColor { Palette.shared.brandPrimary.rawValue }
    var locationControlBorder: UIColor { Palette.shared.brandPrimary.rawValue }
    var locationMapTint: UIColor { Palette.shared.danger.rawValue }
	var locationBubbleEmpty: UIColor { Palette.shared.custom_lightGray2.rawValue }

    var scrollToBottomButtonTint: UIColor { Palette.shared.brandPrimary.rawValue }
    var scrollToBottomButtonBorder: UIColor { Palette.shared.brandPrimary.rawValue }
    var scrollToBottomButtonBackground: UIColor { Palette.shared.gray5.rawValue }

    var voiceMessagePlayButton: UIColor { Palette.shared.gray5.rawValue }
    var voiceMessageIncomePlayBackground: UIColor { Palette.shared.brandPrimary.rawValue }
    var voiceMessageOutcomePlayBackground: UIColor { Palette.shared.gray5.withAlphaComponent(0.25).rawValue }
    var voiceMessageIncomeTime: UIColor { Palette.shared.gray1.rawValue }
    var voiceMessageOutcomeTime: UIColor { Palette.shared.gray5.withAlphaComponent(0.9).rawValue }
    var voiceMessageIncomeProgressMain: UIColor { Palette.shared.brandPrimary.rawValue }
    var voiceMessageIncomeProgressSecondary: UIColor { Palette.shared.brandPrimary.withAlphaComponent(0.3).rawValue }
    var voiceMessageOutcomeProgressMain: UIColor { Palette.shared.gray5.rawValue }
    var voiceMessageOutcomeProgressSecondary: UIColor { Palette.shared.gray5.withAlphaComponent(0.3).rawValue }

    var attachmentBadgeText: UIColor { Palette.shared.gray5.rawValue }
    var attachmentBadgeBorder: UIColor { Palette.shared.gray5.rawValue }
    var attachmentBadgeBackground: UIColor { Palette.shared.brandPrimary.rawValue }

    var imagePickerCheckMark: UIColor { Palette.shared.gray0.rawValue }
    var imagePickerCheckMarkBackground: UIColor { Palette.shared.gray5.rawValue }
    var imagePickerSelectionOverlay: UIColor { Palette.shared.gray0.withAlphaComponent(0.7).rawValue }
    var imagePickerPreviewBackground: UIColor {Palette.shared.custom_lightGray2.rawValue }
    var imagePickerAlbumTitle: UIColor { Palette.shared.gray0.rawValue }
    var imagePickerAlbumCount: UIColor { Palette.shared.gray1.rawValue }
    var imagePickerBottomButtonTint: UIColor { Palette.shared.gray0.rawValue }
    var imagePickerBottomButtonDisabledTint: UIColor { Palette.shared.gray0.withAlphaComponent(0.5).rawValue }
    var imagePickerButtonsBackground: UIColor { Palette.shared.gray5.rawValue }
    var imagePickerBackground: UIColor { Palette.shared.gray5.rawValue }
    var imagePickerButtonsBorderShadow: UIColor { Palette.shared.gray1.rawValue }
    var imagePickerAlbumsSeparator: UIColor { Palette.shared.gray3.rawValue }

    var imageBubbleEmpty: UIColor { Palette.shared.custom_lightGray2.rawValue }
    var imageBubbleProgress: UIColor { Palette.shared.gray5.rawValue }
    var imageBubbleProgressUntracked: UIColor { Palette.shared.gray5.withAlphaComponent(0.5).rawValue }
    var imageBubbleBlurColor: UIColor { Palette.shared.mainBlack.withAlphaComponent(0.5).rawValue }

    var documentButtonTint: UIColor { Palette.shared.gray5.rawValue }
    var documentButtonIncomeBackground: UIColor { Palette.shared.brandPrimary.rawValue }
    var documentButtonOutcomeBackground: UIColor { Palette.shared.gray5.withAlphaComponent(0.25).rawValue }
    var documentIncomeProgressBackground: UIColor { Palette.shared.brandPrimary.rawValue }
    var documentProgressIncome: UIColor { Palette.shared.gray5.rawValue }
    var documentIncomeProgressUntracked: UIColor { Palette.shared.gray5.withAlphaComponent(0.5).rawValue }
    var documentOutcomeProgressBackground: UIColor { Palette.shared.gray5.rawValue }
    var documentOutcomeProgress: UIColor { Palette.shared.brandPrimary.rawValue }
    var documentOutcomeProgressUntracked: UIColor { Palette.shared.brandPrimary.withAlphaComponent(0.5).rawValue }

    var videoInfoBackground: UIColor { Palette.shared.gray0.withAlphaComponent(0.3).rawValue }
    var videoInfoMain: UIColor { Palette.shared.gray5.rawValue }

	var replySwipeBackground: UIColor { Palette.shared.chatReplySwipeBackground.withAlphaComponent(0.25).rawValue }
    var replySwipeIcon: UIColor { Palette.shared.gray5.rawValue }

    var attachmentsPreviewRemoveItemTint: UIColor { Palette.shared.gray5.rawValue }

    var replyPreviewIcon: UIColor { Palette.shared.gray1.withAlphaComponent(0.5).rawValue }
    var replyPreviewNameText: UIColor { Palette.shared.brandPrimary.rawValue }
    var replyPreviewReplyText: UIColor { Palette.shared.gray0.rawValue }
    var replyPreviewRemoveButton: UIColor { Palette.shared.brandPrimary.rawValue }

    var navigationBarText: UIColor { Palette.shared.gray0.rawValue }
    var navigationBarTint: UIColor { Palette.shared.gray0.rawValue }

	var pickerAlertControllerTint: UIColor? { Palette.shared.gray0.rawValue }

    var replyIncomeLineBackground: UIColor { Palette.shared.brandPrimary.rawValue }
    var replyIncomeNameText: UIColor { Palette.shared.brandPrimary.rawValue }
    var replyIncomeContentText: UIColor { Palette.shared.gray0.rawValue }
    var replyOutcomeLineBackground: UIColor { Palette.shared.gray5.rawValue }
    var replyOutcomeNameText: UIColor { Palette.shared.gray5.rawValue }
    var replyOutcomeContentText: UIColor { Palette.shared.gray5.rawValue }

	var fullImageCloseButtonTintColor: UIColor { Palette.shared.gray5.withAlphaComponent(0.5).rawValue }
	var fullImageCloseButtonBackgroundColor: UIColor { Palette.shared.gray1.withAlphaComponent(0.5).rawValue }

	var textContentOutcomeLinkColor: UIColor? { nil }
	var textContentIncomeLinkColor: UIColor? { nil }

    init() { }
}

// Type annotation should be presented for correct protocol conformance
final class ChatImageSet: ThemeImageSet {
	private(set) lazy var chatBackground = UIImage.pch_fromColor(Palette.shared.gray4.rawValue)
    private(set) lazy var attachPickersButton = UIImage(named: "chat_attach_icon") ?? UIImage()
    private(set) lazy var sendMessageButton = UIImage(named: "chat_send_icon") ?? UIImage()
    private(set) lazy var voiceMessageButton = UIImage(named: "chat_voice_icon") ?? UIImage()
	private(set) lazy var fullImageCloseButton = UIImage(named: "full_image_close_button") ?? UIImage()
}

final class ChatStyleProvider: StyleProvider {
    var messagesCell: MessagesCellStyleProvider.Type { ChatMessagesCellStyleProvider.self }
}

final class ChatFontProvider: FontProvider {
	private static let regular11 = FontDescriptor(font: Palette.shared.primeFont.with(size: 11).rawValue, lineHeight: 11)
    private static let regular12 = FontDescriptor(font: Palette.shared.primeFont.with(size: 12).rawValue, lineHeight: 14, baselineOffset: 1.0)
    private static let regular15 = FontDescriptor(font: Palette.shared.primeFont.with(size: 15).rawValue, lineHeight: 19, baselineOffset: 1.0)

    let timeSeparator: FontDescriptor = ChatFontProvider.regular12
    let locationPickTitle: FontDescriptor = ChatFontProvider.regular15
    let locationPickSubtitle: FontDescriptor = ChatFontProvider.regular11

    var badge: FontDescriptor { Palette.shared.primeFont.with(size: 15).rawValue.pch_fontDescriptor }

    var pickerVideoDuration: FontDescriptor { Palette.shared.primeFont.with(size: 12).rawValue.pch_fontDescriptor }
    var pickerAlbumTitle: FontDescriptor { Palette.shared.primeFont.with(size: 15).rawValue.pch_fontDescriptor }
    var pickerAlbumCount: FontDescriptor { Palette.shared.primeFont.with(size: 15).rawValue.pch_fontDescriptor }
    var pickerActionsButton: FontDescriptor { Palette.shared.primeFont.with(size: 15).rawValue.pch_fontDescriptor }

    var previewVideoDuration: FontDescriptor { Palette.shared.primeFont.with(size: 12).rawValue.pch_fontDescriptor }

    let voiceMessageRecordingTime: FontDescriptor = ChatFontProvider.regular15
    let voiceMessageRecordingTitle: FontDescriptor = ChatFontProvider.regular15

    let replyName: FontDescriptor = ChatFontProvider.regular12
    let replyText: FontDescriptor = ChatFontProvider.regular15
    let senderPlaceholder: FontDescriptor = ChatFontProvider.regular15
    var senderBadge: FontDescriptor { Palette.shared.primeFont.with(size: 12).rawValue.pch_fontDescriptor }
    let documentName: FontDescriptor = ChatFontProvider.regular15
    var documentSize: FontDescriptor = ChatFontProvider.regular11
    let videoInfoTime: FontDescriptor = ChatFontProvider.regular11
    let contactTitle: FontDescriptor = ChatFontProvider.regular15
    let contactPhone: FontDescriptor = ChatFontProvider.regular11
    let voiceMessageDuration: FontDescriptor = ChatFontProvider.regular11
    let messageText: FontDescriptor = ChatFontProvider.regular15
    let messageInfoTime: FontDescriptor = ChatFontProvider.regular11

    var messageReplyName: FontDescriptor {
		FontDescriptor(font: Palette.shared.primeFont.with(size: 12, weight: .medium).rawValue, lineHeight: 13, baselineOffset: 1.0)
    }
    let messageReplyText: FontDescriptor = ChatFontProvider.regular12

    var navigationTitle: FontDescriptor { Palette.shared.primeFont.with(size: 16, weight: .medium).rawValue.pch_fontDescriptor }
    var navigationButton: FontDescriptor { Palette.shared.primeFont.with(size: 12).rawValue.pch_fontDescriptor }
}

final class ChatLayoutProvider: LayoutProvider {
    var textNormalMessageInsets: UIEdgeInsets { .init(top: 10, left: 15, bottom: 12, right: 15) }
    var textReplyMessageInsets: UIEdgeInsets { .init(top: 8, left: 15, bottom: 12, right: 15) }
    var videoInfoPlayImageRightMargin: CGFloat { 6.0 }
}

final class ChatRequestsCustomLayoutProvider: LayoutProvider {
    var messageSenderHorizontalInset: CGFloat { 16.0 }
    var textNormalMessageInsets: UIEdgeInsets { .init(top: 10, left: 15, bottom: 12, right: 15) }
    var textReplyMessageInsets: UIEdgeInsets { .init(top: 8, left: 15, bottom: 12, right: 15) }
    var videoInfoPlayImageRightMargin: CGFloat { 6.0 }
}

final class ChatMessagesCellStyleProvider: MessagesCellStyleProvider {
    static func updateStyle(
        of bubbleView: UIView,
        bubbleBorderLayer: CAShapeLayer,
        for meta: MessageContainerModelMeta
    ) {
        if bubbleView.bounds.isEmpty {
            return
       }

        let cornerRadiusDefault: CGFloat = 15
        let cornerRadiusSmall: CGFloat = 7

        let cornerPath: UIBezierPath
        switch meta.author {
        case .me:
            cornerPath = UIBezierPath.pch_make(
                with: bubbleView.bounds,
                topLeftRadius: cornerRadiusDefault,
                topRightRadius: cornerRadiusDefault,
                bottomLeftRadius: cornerRadiusDefault,
                bottomRightRadius: meta.isNextMessageOfSameUser ? cornerRadiusDefault : cornerRadiusSmall
            )
        case .anotherUser:
            cornerPath = UIBezierPath.pch_make(
                with: bubbleView.bounds,
                topLeftRadius: cornerRadiusDefault,
                topRightRadius: cornerRadiusDefault,
                bottomLeftRadius: meta.isNextMessageOfSameUser ? cornerRadiusDefault : cornerRadiusSmall,
                bottomRightRadius: cornerRadiusDefault
            )
		}

        let pathMask = CAShapeLayer()
        pathMask.path = cornerPath.cgPath

        bubbleView.layer.mask = pathMask
        bubbleBorderLayer.path = cornerPath.cgPath
	}
}
// swiftlint:enable force_unwrapping

