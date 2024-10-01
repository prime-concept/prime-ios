enum HotelGuestsFormField {
    case rowView(HotelGuestsRowViewModel)
    case headerView(String)
    case childRowView(HotelGuestsChildRowViewModel)
}

struct HotelGuestsRowViewModel {
    enum Field {
        case adults, children, rooms

        var minimumAmount: Int {
            switch self {
            case .adults:
                return 1
            case .children:
                return 0
            case .rooms:
                return 1
            }
        }
    }

    let field: Field
    let title: String
    let isSubtractionEnabled: Bool
    var count: Int
}

struct HotelGuestsChildRowViewModel: Equatable {
    static let minimumAge = 0

    let isSubtractionEnabled: Bool
    let index: Int
    var age: Int

    var title: String {
        "hotel.guests.child".localized + " \(index + 1)"
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.index == rhs.index
    }
}
