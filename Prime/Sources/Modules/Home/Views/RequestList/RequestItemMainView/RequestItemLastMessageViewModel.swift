import UIKit
import ChatSDK

struct RequestItemLastMessageViewModel: Equatable, Hashable {
    let isIncome: Bool
    let text: String
    let preview: UIImage?
    let icon: UIImage?
    let dateTime: String
    var unreadCount: Int
	let status: MessageStatus
    var statusImage: UIImage?
	var messengerIcon: UIImage?
}
