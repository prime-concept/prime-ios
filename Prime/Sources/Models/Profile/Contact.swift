struct Contact: Codable {
    var id: Int?
    var firstName: String?
    var middleName: String?
    var lastName: String?
    var birthDate: String?
    var contactType: ContactType?
    var emails: [Email]?
    var phones: [Phone]?
    var documents: [Document]?
}

struct Contacts: Codable {
    let data: [Contact]?
}

struct ContactType: Codable, Equatable {
    let id: Int?
    let name: String?
}

struct ContactTypes: Codable {
    let data: [ContactType]
}
