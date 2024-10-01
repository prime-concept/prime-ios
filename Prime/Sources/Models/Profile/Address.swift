import Foundation

struct Address: Codable {
    let id: Int?
    let latitude: Double?
    let longitude: Double?
    let address: String?
    let countryId: Int?
    let cityId: Int?
    let country: Country?
    let city: City?
    let isPrimary: Bool?

    let attention: Bool?
    let index: String?
    let flat: String?
    let transport: String?
    let comment: String?
    let isDeleted: Bool?
    let street: String?
    let house: String?
    let building: String?
    let ownership: String?
    let section: String?
    let floor: String?
    let office: String?
    let region: String?
    let addressType: AddressType?
    let streetType: StreetType?
    let distance: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case latitude, longitude
        case address, countryId, cityId
        case country, city
        case isPrimary = "primaryFlag"
        case isDeleted = "deleted"
        case attention, index, flat, transport, comment, street, house, building
        case ownership, section, floor, office, region, streetType, distance
        case addressType = "type"
    }
}

struct Addresses: Codable {
    let data: [Address]?
}

struct AddressType: Codable {
    let id: Int?
    let name: String?
}

struct AddressTypes: Codable {
    let data: [AddressType]?
}

struct StreetType: Codable {
    let id: Int?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}
