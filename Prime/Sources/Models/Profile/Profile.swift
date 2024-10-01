struct Profile: Codable, Equatable {
	struct Level: Codable {
		let id: Int?
		let name: String?
		let color: String?
		let updatedAt: String?
		let deleted: Bool?
	}

	var username: String?
	let clubPhone: String?
	let clubCard: String?
	let enabled: Bool?
	let phone: String?
	var firstName: String?
	var lastName: String?
	var middleName: String?
	var birthday: String?
	let gender: Int?
	let customerTypeId: Int?
	let projectId: Int?
	let expiryDate: String?
	let deletedAt: String?
	let prefix: String?
	let profileType: String?
	let assistant: Assistant?
	let level: Level?
	let grantedAuthorities: [String]

	var levelName: String? {
		if self.level?.deleted == true {
			return nil
		}

		return self.level?.name
	}

	var isEmptyProfile: Bool {
		self.username == "__EMPTY_PROFILE__"
	}

	static let empty = Profile(username: "__EMPTY_PROFILE__", clubPhone: nil, clubCard: nil, enabled: nil, phone: nil, firstName: nil, lastName: nil, middleName: nil, birthday: nil, gender: nil, customerTypeId: nil, projectId: nil, expiryDate: nil, deletedAt: nil, prefix: nil, profileType: nil, assistant: nil, level: nil, grantedAuthorities: [])

	static func == (lhs: Profile, rhs: Profile) -> Bool {
		lhs.username == rhs.username
	}
}
