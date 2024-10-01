import Foundation

struct AirportsResponse: Codable {
    struct AirportsResponseDict: Codable {
        let airports: [Airport]
    }

    struct AirportsResponseData: Codable {
        let dict: AirportsResponseDict
    }

    let data: AirportsResponseData
}

struct Airport: Codable {
	init(
		id: Int,
		altCountryName: String,
		altCityName: String,
		isHub: Bool = false,
		altName: String? = nil,
		city: String,
		cityId: Int,
		code: String,
		country: String,
		deleted: Bool = false,
		latitude: Double? = nil,
		longitude: Double? = nil,
		name: String,
		updatedAt: Int = 0,
		vipLoungeCost: String? = nil
	) {
		self.id = id
		self.altCountryName = altCountryName
		self.altCityName = altCityName
		self.isHub = isHub
		self.altName = altName
		self.city = city
		self.cityId = cityId
		self.code = code
		self.country = country
		self.deleted = deleted
		self.latitude = latitude
		self.longitude = longitude
		self.name = name
		self.updatedAt = updatedAt
		self.vipLoungeCost = vipLoungeCost
	}

	static let artificialCityId = 0
	static let artificialAirportId = 0

	let id: Int
    let altCountryName: String
    let altCityName: String
    let isHub: Bool?
    let altName: String?
    let city: String
    let code: String
    let country: String
    let deleted: Bool
    let latitude: Double?
    let longitude: Double?
    let name: String
    let updatedAt: Int
    let cityId: Int
    let vipLoungeCost: String?

	var _isHub: Bool {
		self.isHub ?? false
	}
}
