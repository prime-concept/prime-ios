import Foundation

struct Country: Codable, Equatable {
    let id: Int
    let name: String
    let code: String?
    let cities: [City]?
}

struct Countries: Codable {
    let data: [String: [String: [Country]]]
    var countries: [Country] {
        data["dict"]?["countries"] ?? []
    }
}
