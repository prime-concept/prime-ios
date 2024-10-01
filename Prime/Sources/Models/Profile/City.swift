import Foundation

struct City: Codable, Equatable {
    let id: Int
    let name: String
	let country: Country?

    enum CodingKeys: String, CodingKey {
        case id, name, country
    }
}

struct Cities: Codable {
    let data: [City]?
}
