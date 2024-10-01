import UIKit

struct TaskTypeResponse: Decodable {
	let items: [TaskType]

	enum DataKeys: String, CodingKey { case data }
	enum DictKeys: String, CodingKey { case dict }
	enum TaskTypesKeys: String, CodingKey { case taskTypes }

	init(from decoder: Decoder) throws {
		do {
			self.items = try decoder.container(keyedBy: DataKeys.self)
				.nestedContainer(keyedBy: DictKeys.self, forKey: .data)
				.nestedContainer(keyedBy: TaskTypesKeys.self, forKey: .dict)
				.decode([TaskType].self, forKey: .taskTypes)
		} catch {
			throw error
		}
	}
}

struct TaskType: Codable {
	let id: Int
	let name: String
	var deleted: Bool?
	let groupId: Int?
	let rowNumber: Int?

	var type: TaskTypeEnumeration? {
		TaskTypeEnumeration(id: self.id)
	}

    internal init(
        id: Int,
        name: String,
        deleted: Bool = false,
        groupId: Int? = nil,
        rowNumber: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.deleted = deleted
        self.groupId = groupId
        self.rowNumber = rowNumber
    }
}

extension TaskType {
	func localizedName(lang: String) -> String {
		let tasks = Self.cache[lang]
		let task = tasks?.first { $0.id == self.id }
		let name = task?.name ?? self.type?.defaultLocalizedName ?? "Unknown"

		return name
	}

	var localizedName: String {
		self.localizedName(lang: Locale.primeLanguageCode)
	}

	var image: UIImage? {
		self.type?.defaultImage ?? UIImage(named: "default_task_type_icon")
	}
}

extension TaskType {
	static func taskType(_ id: Int) -> TaskType? {
		let cache = Self.cache[Locale.primeLanguageCode]
		if let taskType = cache?.first(where: { $0.id == id }) {
			return taskType
		}

		if let enoom = TaskTypeEnumeration(id: id) {
			return TaskType(id: id, name: enoom.defaultLocalizedName)
		}

		return nil
	}

	static func image(for id: Int) -> UIImage? {
		if let taskType = Self.taskType(id) {
			return taskType.image
		}

		if let type = TaskTypeEnumeration(id: id) {
			return type.defaultImage
		}

		return nil
	}

	static func localizedName(for id: Int) -> String? {
		if let taskType = Self.taskType(id) {
			return taskType.localizedName
		}

		if let type = TaskTypeEnumeration(id: id) {
			return type.defaultLocalizedName
		}

		return nil
	}
}

extension TaskType {
	@PersistentCodable(fileName: "TaskType.cache", async: false)
	fileprivate static var cache: [String: [TaskType]] = [:]

	@PersistentCodable(fileName: "TaskType.taskTypesRows.cache", async: false)
	fileprivate static var taskTypesRows: [Int: [Int]] = [:]

	static func initCache() {
		_ = Self.cache
		_ = Self.taskTypesRows
	}

	static var hasCacheForCurrentLocale: Bool {
		let localizedCache = self.cache[Locale.primeLanguageCode]
		return localizedCache?.count ?? 0 > 0
	}

	static var hasCachedRows: Bool {
        !taskTypesRows.isEmpty
	}

	static func updateCache(_ key: String, _ items: [TaskType]) {
		Self.cache[key] = items
		Self.cache.write(to: "TaskType.cache")
	}

	static func updateTaskTypesRows(_ items: [TaskType]) {
		let rowIndices = Set(items.compactMap(\.rowNumber))

		var rowsToTypes = [Int: [Int]]()

		rowIndices.forEach { row in
			rowsToTypes[row] = items
				.filter { $0.rowNumber == row }
				.map(\.id)
		}

		Self.taskTypesRows = rowsToTypes
		Self.taskTypesRows.write(to: "TaskType.taskTypesRows.cache")
	}

	static func taskTypesFor(row: Int) -> [Int]? {
		Self.taskTypesRows[row]
	}
}
