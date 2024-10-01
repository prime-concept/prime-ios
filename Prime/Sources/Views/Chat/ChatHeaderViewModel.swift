import Foundation

struct ChatHeaderViewModel {
    let name: String
    let role: String

    init(assistant: Assistant) {
        self.name = "\(assistant.firstName)"
        self.role = assistant.profileType.rawValue
    }
}
