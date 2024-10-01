struct Email: Codable {
    let id: Int?
    let email: String?
    let comment: String?
    let isPrimary: Bool?
    let emailType: EmailType?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case comment
        case isPrimary = "primary"
        case emailType
    }
}

struct Emails: Codable {
    let data: [Email]?
}

struct EmailType: Codable {
    let id: Int?
    let name: String?
}

struct EmailTypes: Codable {
    let data: [EmailType]?
}
