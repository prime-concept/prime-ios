import Foundation
import CoreLocation
import PromiseKit

typealias Distance = Int

protocol AirportSearchServiceProtocol {
    var airports: [Airport] { get set }
    func setSearched(airport: Airport)

    func getRecentlySearchedAirports(query: String) -> [Airport]
    func getClosestAirports() -> Promise<[(Airport, Distance)]>
    func queryAirports(query: String) -> [Airport]
    func searchAirport(by id: Int) -> Airport?
}

class AirportSearchService: AirportSearchServiceProtocol {
    private let locationService: LocationServiceProtocol

    private let maxRecentlySearchedCount = 5
    private let closestAirportsDistanceThresholdMeters: Double = 100_000
    private let maxClosestAirportsCount = 5

    var airports: [Airport] = []

    private static let recentlySearchedAirportsIDsKey = "recentlySearchedAirportsIDs"
    private var recentlySearchedAirportsIDs: [Int] {
        get {
            UserDefaults.standard.array(forKey: AirportSearchService.recentlySearchedAirportsIDsKey) as? [Int] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AirportSearchService.recentlySearchedAirportsIDsKey)
        }
    }

    init(locationService: LocationServiceProtocol) {
        self.locationService = locationService
    }

    func setSearched(airport: Airport) {
        recentlySearchedAirportsIDs = [airport.id] + recentlySearchedAirportsIDs
    }

    func getRecentlySearchedAirports(query: String) -> [Airport] {
        Array(
            recentlySearchedAirportsIDs.compactMap { airportID in
                airports.first(where: { $0.id == airportID })
            }.filter {
                self.isAirportFiltered(airport: $0, query: query.trimmingCharacters(in: .whitespaces))
            }.prefix(maxRecentlySearchedCount)
        )
    }

    func getClosestAirports() -> Promise<[(Airport, Distance)]> {
        Promise { seal in
            self.locationService.fetchLocation { [weak self] result in
                guard let strongSelf = self else {
                    seal.fulfill([])
                    return false
                }

                switch result {
                case .success:
                    let air: [(Airport, Distance)] = Array(
                            strongSelf.airports
                                .compactMap { airport -> (airport: Airport, dist: CLLocationDistance)? in
                                    if let lat = airport.latitude,
                                       let lon = airport.longitude,
                                       let distance = strongSelf.locationService.distanceFromLocation(
                                        to: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                       ),
                                       distance < strongSelf.closestAirportsDistanceThresholdMeters {
                                        return (airport: airport, dist: distance)
                                    } else {
                                        return nil
                                    }
                                }.sorted(by: {
                                    $0.dist < $1.dist
                                })
                                .map { ($0.airport, Int($0.dist / 1000)) }
                                .prefix(strongSelf.maxClosestAirportsCount)
                        )
                    seal.fulfill(air)
                case .error:
                    seal.fulfill([])
                }

				return false
            }
        }
    }

    func queryAirports(query: String) -> [Airport] {
        let query = query.lowercased().trimmingCharacters(in: .whitespaces)

		let filteredAirports = self.airports.filter { self.isAirportFiltered(airport: $0, query: query) }
		let airportsCountByCities = Dictionary(grouping: filteredAirports.map(\.city)) { $0.lowercased() }

		let sortedAirports = filteredAirports.sorted {
			let firstCity = $0.city.lowercased()
			let secondCity = $1.city.lowercased()

			if firstCity == query {
				return true
			}
			if secondCity == query {
				return false
			}
			if firstCity.hasPrefix(query), secondCity.hasPrefix(query) {
				let firstCityAirportsCount = airportsCountByCities[firstCity]?.count ?? 0
				let secondCityAirportsCount = airportsCountByCities[secondCity]?.count ?? 0

				if firstCityAirportsCount != secondCityAirportsCount {
					return firstCityAirportsCount > secondCityAirportsCount
				}

				return firstCity.count < secondCity.count
			} else {
				if firstCity.hasPrefix(query) {
					return true
				}
				if secondCity.hasPrefix(query) {
					return false
				}
			}

			if !firstCity.contains(query), secondCity.contains(query) {
				return false
			}
			if firstCity.contains(query), !secondCity.contains(query) {
				return true
			}

			return $0.name.lowercased() < $1.name.lowercased()
		}
		return sortedAirports
    }

    private func isAirportFiltered(airport: Airport, query: String) -> Bool {
		let query = query.lowercased()

        if query.isEmpty {
            return true
        }

		let filters = [
			airport.altCityName,
			airport.name,
			airport.code,
			airport.city,
			airport.country
		].map { $0.lowercased() }

		let isFiltered = filters.contains{ $0.contains(query) }

		return isFiltered
    }

    func searchAirport(by id: Int) -> Airport? {
        airports.first { $0.id == id }
    }
}
