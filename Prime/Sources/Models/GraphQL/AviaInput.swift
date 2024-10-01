struct AviaInput: Encodable {
    let adults: Int
    let children: Int
    let infants: Int
    let serviceClass: String
    let routes: [Route]
    let tripType: Int
}

struct Route: Encodable {
    let arrivalDate: String
    let arrivalLocation: String
    let departureDate: String
    let departureLocation: String
    var flightNumber: String?
}

struct LocationInput: Encodable {
    let id: Int
    let name: String
}
