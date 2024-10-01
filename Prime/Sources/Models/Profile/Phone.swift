struct Phone: Codable {
    let id: Int?
    let phone: String?
    let comment: String?
    let isPrimary: Bool?
    let phoneType: PhoneType?
    let isAttention: Bool?
    let status: String?
    let isUsedForAlfaclick: Bool?
    let isUsedForMobileApp: Bool?
    let isForbiddenForSMS: Bool?
    let isPersonalAssistantPhone: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case comment
        case isPrimary = "primary"
        case phoneType
        case isAttention = "attention"
        case status
        case isUsedForAlfaclick = "useForAlfaclick"
        case isUsedForMobileApp = "useForMobileApp"
        case isForbiddenForSMS = "forbiddenForSms"
        case isPersonalAssistantPhone = "personalAssistantPhone"
    }
}

struct Phones: Codable {
    let data: [Phone]?
}

struct PhoneType: Codable {
    let id: Int?
    let name: String?
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDeleted = "deleted"
    }
}

struct PhoneTypes: Codable {
    let data: [PhoneType]?
}
