import UIKit

struct HotelFormViewModel {
    let placeOfResidence: HotelFormRowViewModel
    let dates: HotelFormRowViewModel
    let guests: HotelFormRowViewModel
}

struct HotelFormRowViewModel {
    enum HotelFormField {
        case hotel, dates, guests

        var iconImage: UIImage? {
            switch self {
            case .hotel:
                return UIImage(named: "avia_point")
            case .dates:
                return UIImage(named: "avia_calendar")
            case .guests:
                return UIImage(named: "avia_passenger")
            }
        }

        var placeholder: String {
            switch self {
            case .hotel:
                return "hotel.picker.placeholder".localized
            case .dates:
                return "hotel.dates.picker.placeholder".localized
            case .guests:
                return ""
            }
        }
    }

    let field: HotelFormField
    let value: String
    let isSeparatorHidden: Bool

    init(field: HotelFormField, value: String = "", isSeparatorHidden: Bool = false) {
        self.field = field
        self.value = value
        self.isSeparatorHidden = isSeparatorHidden
    }
}
