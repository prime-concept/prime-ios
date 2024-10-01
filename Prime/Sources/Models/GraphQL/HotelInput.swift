struct HotelInput: Encodable {
    let adultsCount: Int
    let childCount: Int
    let checkInDate: String
    let checkOutDate: String
    let city: String?
    let country: String?
    let hotelId: Int?
    let hotelName: String?
    let kidsBirthdays: String
    let numOfRooms: String
}
