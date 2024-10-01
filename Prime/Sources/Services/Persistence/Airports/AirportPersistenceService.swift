import Foundation
import PromiseKit

protocol AirportPersistenceServiceProtocol {
    var lastUpdatedAt: Int { get }

	func delete()
    func retrieve() -> Guarantee<[Airport]>
    func save(airports: [Airport]) -> Promise<Void>
}

final class AirportPersistenceService: RealmPersistenceService<Airport>, AirportPersistenceServiceProtocol {

	static let shared = AirportPersistenceService()

	@PersistentCodable(fileName: "AirportPersistenceService.lastUpdated", async: false)
	var lastUpdatedAt: Int = 0

	func delete() {
		self.deleteAll()
	}

    func retrieve() -> Guarantee<[Airport]> {
        Guarantee<[Airport]> { seal in
            let airports = self.read()
            seal(airports)
        }
    }

    func save(airports: [Airport]) -> Promise<Void> {
        var airportArray = airports

        for airport in airports where airport.deleted {
            self.delete(id: airport.id)

            if let index = airportArray.firstIndex(where: { $0.id == airport.id }) {
                airportArray.remove(at: index)
            }
        }

        return Promise<Void> { seal in
            self.write(objects: airportArray)
            self.calculateLastUpdatedAt()
            seal.fulfill_()
        }
    }

    func calculateLastUpdatedAt() {
        let airports = self.read()
        self.lastUpdatedAt = airports.map { $0.updatedAt }.max() ?? 0
    }

    private func delete(id: Int) {
        self.delete(predicate: NSPredicate(format: "id = %@", NSNumber(integerLiteral: id)))
    }
}
