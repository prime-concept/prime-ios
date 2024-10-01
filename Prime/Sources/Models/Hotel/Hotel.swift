import Foundation

struct Hotel: Codable, Equatable {
    let id: Int
    let name: String
    let city: HotelCity?
    let latitude: Double?
    let longitude: Double?
    let stars: Int?
}

extension Hotel: Comparable {
    static func < (lhs: Hotel, rhs: Hotel) -> Bool {
        (lhs.stars^, rhs.name^.lowercased()) > (rhs.stars^, lhs.name^.lowercased())
    }
}

struct HotelsResponse: Codable {
    let data: [String: [Hotel]]?

    var hotels: [Hotel] {
        data?["partners"] ?? []
    }
}

struct HotelCity: Codable, Hashable {
    struct HotelCountry: Codable, Equatable {
        let id: Int?
        let name: String?
    }

    let id: Int?
    let name: String?
    let country: HotelCountry?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
