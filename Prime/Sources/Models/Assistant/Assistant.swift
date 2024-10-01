import Foundation

struct Assistant: Codable {
	struct ContactType: Codable {
		let name: String
	}

    let lastName: String
    let firstName: String
    let phone: String?
	let profileType = ProfileType.assistant

	enum CodingKeys: String, CodingKey {
		case lastName, firstName, phone, contactType, profileType
	}

    init(firstName: String, lastName: String) {
        self.lastName = lastName
        self.firstName = firstName
        self.phone = nil
    }

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let lastName = (try? values.decode(String.self, forKey: .lastName)) ?? ""
		let firstName = (try? values.decode(String.self, forKey: .firstName)) ?? lastName

		self.lastName = lastName
		self.firstName = firstName
		
		self.phone = try? values.decode(String.self, forKey: .phone)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.lastName, forKey: .lastName)
		try container.encode(self.firstName, forKey: .firstName)
		try container.encode(self.phone, forKey: .phone)
		try container.encode(self.profileType, forKey: .profileType)
	}
}

enum ProfileType: String, Codable {
    case assistant = "ASSISTANT"
    case customer = "CUSTOMER"
}
