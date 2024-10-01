struct HotelGuests {
    var adults: Int
    var children: Children
    var rooms: Int

    static var `default`: Self {
        .init(
            adults: 2,
            children: Children(),
            rooms: 1
        )
    }

    var total: Int {
        adults + children.ages.count
    }
}

struct Children {
    var ages: [Int] = []

    var amount: Int {
        ages.count
    }
}
