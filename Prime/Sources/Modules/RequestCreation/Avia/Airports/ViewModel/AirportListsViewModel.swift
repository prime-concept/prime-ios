import Foundation

struct AirportListsViewModel {
    var airportLists: [AirportListViewModel]
    var isFirstSectionNear = false
    var mayTapOnCityHub = true
    
    init(
        queriedAirports: [Airport],
        airportsNear: [(Airport, Distance)]
    ) {
        airportLists = []
        if !airportsNear.isEmpty {
            isFirstSectionNear = true
            airportLists += [
                AirportListViewModel(
                    title: "airports.near".localized,
                    airports: airportsNear.map { AirportViewModel(airport: $0.0, distance: "\($0.1) km") }
                )
            ]
        }

        if queriedAirports.isEmpty {
            return
        }

		let sortedCities = queriedAirports.map(\.city).unique(by: \.self)
        let airportsByCity = queriedAirports
            .reduce(into: [String: [Airport]]()) { (dict, airport) -> () in
                guard dict[airport.city] != nil else {
                    dict[airport.city] = [airport]
                    return
                }
                dict[airport.city]!.append(airport)
            }

		sortedCities.forEach { city in
            let airports = airportsByCity[city]^
            let country = airports.first?.country
            airportLists += [
                AirportListViewModel(
                    title: city,
                    subtitle: country ?? "",
                    airports: airports.map { airport in
                        AirportViewModel(
                            id: airport.id,
                            isHub: airport.isHub^,
                            title: airport.name,
                            code: airport.code
                        )
                    }
                )
            ]
        }
    }
}

struct AirportListViewModel: Equatable {
    private var id = UUID()
    var header: AirportListHeaderViewModel
    var airports: [AirportViewModel]
    var isExpanded: Bool

    init(
        title: String,
        subtitle: String = "",
        airports: [AirportViewModel],
        isExpanded: Bool = true
    ) {
        self.header = AirportListHeaderViewModel(
            title: title,
            subtitle: subtitle,
            isExpanded: isExpanded
        )
        self.airports = airports
        self.isExpanded = isExpanded
    }
    
    static func == (lhs: AirportListViewModel, rhs: AirportListViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct AirportViewModel {
    var id: Int
    var isHub: Bool
    var title: String
    var subtitle: String?
    var code: String
    var distance: String?
    
    init(airport: Airport, distance: String = "") {
        self.id = airport.id
        self.isHub = airport.isHub^
        self.title = airport.name
        self.subtitle = "\(airport.city), \(airport.country)"
        self.code = airport.code
        self.distance = distance
    }
    
    init(id: Int, isHub: Bool, title: String, code: String) {
        self.id = id
        self.isHub = isHub
        self.title = title
        self.code = code
    }
}
