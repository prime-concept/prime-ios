import Foundation
import RealmSwift

protocol RealmPersistenceServiceProtocol: AnyObject {
    associatedtype PersistentType = RealmObjectConvertible

	func read(predicate: NSPredicate) -> [PersistentType]
	func read() -> [PersistentType]

    func write(objects: [PersistentType])
    func write(object: PersistentType)

	func delete(predicate: NSPredicate)
	func deleteAll()
}

enum RealmPersistence {
	static let realmRootURL = try? FileManager.default.url(
		for: .documentDirectory,
		in: .userDomainMask,
		appropriateFor: nil,
		create: true
	).appendingPathComponent("Realm")

	// Создаем экземпляры сервисов, чтобы работала очистка кэша. Сервисы всегда живы
	// и всегда могут поймать нотификейшен для удаления своих данных.
	static func initPersistenceServices() {
		_ = TaskPersistenceService.shared
		_ = AirportPersistenceService.shared
		_ = CalendarEventsService.shared
	}
}

class RealmPersistenceService<T: RealmObjectConvertible>: RealmPersistenceServiceProtocol {
	var schemaVersion: UInt64 {
		1
	}

	var fileName: String {
		"\(T.self).realm"
	}

	var fileURL: URL? {
		let fileURL = RealmPersistence.realmRootURL?
			.appendingPathComponent("PRIME")
			.appendingPathComponent(self.fileName)

		try? fileURL?.createWithSubdirectoriesIfNeeded()
		return fileURL
	}

	var deletesOnMigration: Bool {
		true
	}

	init() {
		Notification.onReceive(.loggedOut, .shouldClearCache) { [weak self] _ in
			self?.deleteAll()
		}
	}

	private func makeConfig() -> Realm.Configuration {
		DebugUtils.shared.log(sender: self, "PERSERV WILL CREATE FILE FOR REALM: \(self.fileURL?.description ?? "")")

		return Realm.Configuration(
			fileURL: self.fileURL,
			schemaVersion: UInt64(self.schemaVersion),
			migrationBlock: { migration, oldVersion in
				self.migrate(migration, oldVersion)
			},
			deleteRealmIfMigrationNeeded: self.deletesOnMigration
		)
	}

	private lazy var config = self.makeConfig()

	// !OVERRIDABLE!
	func migrate(_ migration: Migration, _ oldSchemaVersion: UInt64) {
		DebugUtils.shared.log(
			sender: self, "schemaVersionDidChange from \(oldSchemaVersion) to \(self.schemaVersion)"
		)
	}

	func write(objects: [T]) {
		do {
			let realm = try Realm(configuration: self.config)
			try realm.write {
				for object in objects {
					realm.create(
						T.RealmObjectType.self,
						value: object.realmObject,
						update: .all
					)
				}
			}
		} catch {
			DebugUtils.shared.log(sender: self, "FAILED TO \(#function), ERROR: \(error.localizedDescription)")
			assertionFailure(error.localizedDescription)
		}
	}

    func write(object: T) {
        write(objects: [object])
    }

	func read(predicate: NSPredicate) -> [T] {
		do {
			let realm = try Realm(configuration: self.config)
			let results = realm
				.objects(T.RealmObjectType.self)
				.filter(predicate)
				.map { T(realmObject: $0) }

			return Array(results)
		} catch {
			DebugUtils.shared.log(sender: self, "FAILED TO \(#function), ERROR: \(error.localizedDescription)")
			assertionFailure(error.localizedDescription)
			return []
		}
    }

    func read() -> [T] {
		do {
			let realm = try Realm(configuration: self.config)
			let results = realm
				.objects(T.RealmObjectType.self)
				.map { T(realmObject: $0) }

			return Array(results)
		} catch {
			DebugUtils.shared.log(sender: self, "FAILED TO \(#function), ERROR: \(error.localizedDescription)")
			assertionFailure(error.localizedDescription)
			return []
		}
    }

	func delete(predicate: NSPredicate) {
		self.delete(nullablePredicate: predicate)
	}

	func deleteAll() {
		DebugUtils.shared.log(sender: self, "PERSISTENCE SERVICE WILL DELETE ALL!")
		self.delete(nullablePredicate: nil)
	}

	private func delete(nullablePredicate: NSPredicate?) {
		do {
			let realm = try Realm(configuration: self.config)
			var objects = realm
				.objects(T.RealmObjectType.self)

			if let predicate = nullablePredicate {
				objects = objects.filter(predicate)
			}

			try realm.write {
				for object in objects {
					realm.delete(object)
				}
			}
		} catch {
			DebugUtils.shared.log(sender: self, "FAILED TO \(#function), ERROR: \(error.localizedDescription)")
			assertionFailure(error.localizedDescription)
		}
	}
}

