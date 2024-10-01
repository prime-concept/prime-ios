
struct VipLoungeInput: Encodable {
    let kind: String
    var transitFlight: Bool?
    var serviceDescription: String?
    var departure: VipLoungeRoute?
    var landing: VipLoungeRoute?
}

struct VipLoungeRoute: Encodable {
    let datetime: String
    let airportAndTerminal: String
    let departureCityId: Int
    let landingCityId: Int
    let flightNumber: String
    let namesAdults: String
    let kidNames: String
    let infantNames: String
}
