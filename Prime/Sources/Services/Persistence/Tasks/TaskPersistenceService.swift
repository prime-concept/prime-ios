import Foundation
import PromiseKit
import RealmSwift

protocol TaskPersistenceServiceProtocol {
	var maxEtag: String? { get }
	var minEtag: String? { get }
	func task(with taskID: Int) -> Guarantee<Task?>
	/// Retrieves not .deleted tasks only
	func retrieve() -> Guarantee<[Task]>
	/// If all == true, returns all tasks, even .deleted
	func retrieve(all: Bool) -> Guarantee<[Task]>
    func save(tasks: [Task]) -> Promise<Void>
    func deleteAll()
	func clearEtags()
	
	func recalculateExtremeEtags(with tasks: [Task])
}

final class TaskPersistenceService: RealmPersistenceService<Task>, TaskPersistenceServiceProtocol {
	override var schemaVersion: UInt64 {
		10
	}

	static let shared = TaskPersistenceService()
	
	@PersistentCodable(fileName: "TaskPersistenceService.minEtag", async: false)
	private(set) var minEtag: String? = nil

	@PersistentCodable(fileName: "TaskPersistenceService.maxEtag", async: false)
	private(set) var maxEtag: String? = nil

	override init() {
		super.init()

		self._minEtag.onFlush = { value, error in
			DebugUtils.shared.log(sender: self, ">ETAGS FLUSH MIN ETAG: \(value ?? "") error: \(error?.localizedDescription ?? "")")
		}

		self._maxEtag.onFlush = { value, error in
			DebugUtils.shared.log(sender: self, ">ETAGS FLUSH MAX ETAG: \(value ?? "") error: \(error?.localizedDescription ?? "")")
		}

		if self.minEtag == nil, self.maxEtag == nil {
			DebugUtils.shared.log(sender: self, "ETAGS ARE NIL, READ ALL TASKS, RECALC EXTREMES!")
			let tasks = self.read()
			self.printStatistics(for: tasks)
			self.recalculateExtremeEtags(with: tasks)
		}

		Notification.onReceive(.loggedOut, .shouldClearTasks) { [weak self] notification in
			DebugUtils.shared.log(sender: self, "DID RECEIVE NOTIFICATION \(notification.name)")
			self?.deleteAll()
		}
	}

	override func migrate(_ migration: Migration, _ oldSchemaVersion: UInt64) {
		super.migrate(migration, oldSchemaVersion)
		self.clearEtags()
	}

	func retrieve(all: Bool) -> Guarantee<[Task]> {
		DebugUtils.shared.log(sender: self, "WILL RETRIEVE ALL TASKS, EVEN DELETED: \(all ? "TRUE" : "FALSE")")

        return Guarantee<[Task]> { seal in
            var tasks = self.read().sorted(by: { $0.isMoreRecentlyUpdated(than: $1) })
			let count = tasks.count
			DebugUtils.shared.log(sender: self, "DID RETRIEVE \(count) TASKS")
			if !all {
				tasks = tasks.skip(\.deleted)
				DebugUtils.shared.log(sender: self, "DID RETRIEVE \(count) TASKS, SKIPPED DELETED, NOW HAVE: \(tasks.count) TASKS")
			}

			if tasks.isEmpty {
				self.minEtag = nil
				self.maxEtag = nil
			}

			self.printStatistics(for: tasks)
			
            seal(tasks)
        }
    }

	private func printStatistics(for tasks: [Task]) {
		let deleted = tasks.filter({ $0.deleted }).count
		let bad = tasks.filter{ $0.isDecodingFailed }.count
		let completed = tasks.filter{ $0.completed }.count

		let statistics = "TASK STATISTICS: ALL \(tasks.count), BAD: \(bad), DELETED: \(deleted), COMPLETED: \(completed)"

		DebugUtils.shared.log(sender: self, statistics)
	}

	func retrieve() -> Guarantee<[Task]> {
		retrieve(all: false)
	}

    func save(tasks: [Task]) -> Promise<Void> {
		let ids = tasks.map{ $0.taskID.description }.joined(separator: ", ")
		DebugUtils.shared.log(sender: self, "WILL SAVE \(tasks.count) TASKS: \(ids)")
		self.printStatistics(for: tasks)

		self.recalculateExtremeEtags(with: tasks)

		return Promise<Void> { seal in
            self.write(objects: tasks)
            seal.fulfill_()
        }
    }

	func task(with taskID: Int) -> Guarantee<Task?> {
		let predicate = NSPredicate(format: "taskID = %ld", taskID)
		return Guarantee<Task?> { seal in
			guard let task = self.read(predicate: predicate).first else {
				seal(nil)
				return
			}
			seal(task)
		}
	}

    override func deleteAll() {
        super.deleteAll()
		self.clearEtags()
    }

	func clearEtags() {
		DebugUtils.shared.log(sender: self, "WILL CLEAR ETAGS!")
		self.minEtag = nil
		self.maxEtag = nil
	}

	func recalculateExtremeEtags(with tasks: [Task]) {
		DebugUtils.shared.log(sender: self, "WILL RECALC EXTREME ETAGS FOR \(tasks.count) TASKS")

		self.printStatistics(for: tasks)

		if tasks.isEmpty {
			return
		}

		let taskIDs = tasks.map{ "\($0.taskID) - \($0.etag ?? "NULL")" }.joined(separator: ", ")

		DebugUtils.shared.log(sender: self, "WILL RECALC EXTREME ETAGS FOR \(tasks.count) TASKS: \(taskIDs)")

		let etags = tasks.compactMap(\.etag)

		if etags.isEmpty {
			DebugUtils.shared.log(sender: self, ">ETAGS RECALC FAILED, NO ETAGS IN BATCH!")
			return
		}

		let minEtag = etags.min()!
		let maxEtag = etags.max()!

		self.minEtag = mostFit(minEtag, self.minEtag, by: <)
		self.maxEtag = mostFit(maxEtag, self.maxEtag, by: >)

		DebugUtils.shared.log(sender: self, ">ETAGS RECALC MIN \(self.minEtag ?? "") MAX \(self.maxEtag ?? "")")
	}

	private static let etagFormatter = with(DateFormatter()) {
		$0.dateFormat = "YYYYMMddHHmmssSSS"
	}

	private static func etagFromUpdatedAt(_ date: Date) -> String {
		Self.etagFormatter.string(from: date)
	}
}
