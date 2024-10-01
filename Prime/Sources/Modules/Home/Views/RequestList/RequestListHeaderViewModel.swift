import Foundation

struct RequestListHeaderViewModel: Equatable, Hashable {
    let activeCount: Int
	let completedCount: Int
    let mayShowCreateNewRequestButton: Bool
	let latestMessageViewModel: RequestItemLastMessageViewModel?
}
