struct HotelsListViewModel {
    let hotels: [HotelViewModel]
    let cities: [HotelCityViewModel]
    let isSearchActive: Bool

    init(hotels: [Hotel], cities: Set<HotelCity>, isSearchActive: Bool = false) {
        self.isSearchActive = isSearchActive
        self.hotels = hotels.map { hotel in
            var distance: String?
            if let latitude = hotel.latitude,
               let longitude = hotel.longitude,
               let distanceDouble = LocationService.shared.distanceFromLocation(
                to: .init(latitude: latitude, longitude: longitude)
               )
            {
                /// in kilometers
                distance = String(Int(distanceDouble) / 1000) + " km"
            }
            return HotelViewModel(
                id: hotel.id,
                title: hotel.name,
                subtitle: hotel.city?.name ?? "",
                stars: hotel.stars,
                distance: distance
            )
        }
        self.cities = cities.map {
            HotelCityViewModel(
                id: $0.id ?? -1,
                title: $0.name ?? "",
                subtitle: $0.country?.name ?? ""
            )
        }
    }
}

extension HotelsListViewModel {
    var hotelsTitle: String {
        "hotel.list.title".localized
    }

    var citiesTitle: String {
        "hotel.cities.list.title".localized
    }
}

struct HotelViewModel {
    let id: Int
    let title: String
    let subtitle: String
    let stars: Int?
    let distance: String?
}

struct HotelCityViewModel {
    let id: Int
    let title: String
    let subtitle: String
}
