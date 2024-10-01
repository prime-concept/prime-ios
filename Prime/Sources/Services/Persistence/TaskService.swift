import Foundation
import PromiseKit

enum TasksFetchDirection: String, Comparable {
    case newer = "ASC"
    case older = "DESC"

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}

protocol TaskServiceProtocol {
    func retrieve() -> Guarantee<[Task]>
    func loadTasksSequentially(
        cached: Bool,
        order: TasksFetchDirection,
        continueLoading: @escaping () -> Void
    )
    func saveTasks(_ tasks: [Task], completion: ((Error?) -> Void)?)
}

final class TaskService: TaskServiceProtocol {
    private let graphQLEndpoint: GraphQLEndpointProtocol
    private let taskPersistenceService: TaskPersistenceServiceProtocol
    private let limit: Int = 100

    private var tasks: [Task] = []
    private var tasksRetryDelay: TimeInterval = 0

    private let networkingQueue = DispatchQueue(label: "TaskServiceNetworkingQueue", qos: .userInitiated)

    static let shared = TaskService(
		taskPersistenceService: TaskPersistenceService.shared,
        graphQLEndpoint: GraphQLEndpoint()
    )

    init(
        taskPersistenceService: TaskPersistenceServiceProtocol,
        graphQLEndpoint: GraphQLEndpointProtocol
    ) {
        self.taskPersistenceService = taskPersistenceService
        self.graphQLEndpoint = graphQLEndpoint
        
        self.taskPersistenceService.retrieve().done { tasks in
            self.tasks = tasks
        }
    }

    // MARK: - TasksServiceProtocol

    func retrieve() -> Guarantee<[Task]> {
        self.taskPersistenceService.retrieve()
    }

    func loadTasksSequentially(
        cached: Bool = false,
        order: TasksFetchDirection = .older,
        continueLoading: @escaping () -> Void
    ) {
        self.networkingQueue.async {
            let etag = order == .older ? self.taskPersistenceService.minEtag :
                                         self.taskPersistenceService.maxEtag
            let language = Locale.primeLanguageCode
            let variables = [
                "lang": AnyEncodable(value: language),
                "limit": AnyEncodable(value: self.limit),
                "etag": AnyEncodable(value: etag),
                "order": AnyEncodable(value: order.rawValue)
            ]

            let endpoint = cached ? self.graphQLEndpoint.cache : self.graphQLEndpoint

            endpoint.request(
                query: GraphQLConstants.tasks,
                variables: variables
            ).promise.then { (response: TasksResponse) -> Promise<[Task]> in
                let possiblyDuplicatedTasks = response.data.viewer
                    .tasks
                    .skip{ $0.isDecodingFailed || $0.deleted }

                let groupedTasks = Dictionary(grouping: possiblyDuplicatedTasks, by: \.updatedAt)
                let sortedDates = groupedTasks.keys.sorted(by: >)

                let newTasks: [Task] = sortedDates.compactMap { date in
                    let tasks = groupedTasks[date]!

                    if tasks.count == 1 {
                        return tasks[0]
                    }

                    let biggestEtagTask = tasks.sorted { task1, task2 in
                        let biggestEtag = mostFit(task1.etag, task2.etag, by: >)
                        return biggestEtag == task1.etag
                    }[0]

                    return biggestEtagTask
                }

                return Promise<[Task]> { [weak self] seal in
                    self?.saveTasks(newTasks) { error in
                        guard let error = error else {
                            seal.fulfill(newTasks)
                            return
                        }

                        seal.reject(error)
                    }
                }
            }.done { [weak self] currentBatchOfTasks in
                guard let self = self else {
                    return
                }

                self.tasksRetryDelay = 0

                guard currentBatchOfTasks.isEmpty else {
                    continueLoading()
                    return
                }
            }.catch { error in
                AnalyticsReportingService
                    .shared.log(
                        name: "[ERROR] \(Swift.type(of: self)) tasks fetch failed",
                        parameters: error.asDictionary
                    )

                delay(self.tasksRetryDelay) {
                    if self.tasksRetryDelay > 10 {
                        return
                    }
                    self.tasksRetryDelay += 1
                    continueLoading()
                }
            }
        }
    }

    func saveTasks(_ tasks: [Task], completion: ((Error?) -> Void)?) {
        let tasks: [Task] = tasks.compactMap { newTask in

            guard let oldTask = self.tasks.first(
                where: { $0.taskID == newTask.taskID }
            ) else {
                return newTask
            }

            guard newTask.lastChatMessage?.timestamp ?> oldTask.lastChatMessage?.timestamp else {
                return nil
            }

            var newTask = newTask
            newTask.lastChatMessage = oldTask.lastChatMessage

            return newTask
        }

        guard !tasks.isEmpty else {
            return
        }

        self.taskPersistenceService
            .save(tasks: tasks)
            .done { completion?(nil) }
            .catch {
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) tasks save failed",
						parameters: $0.asDictionary
					)
				completion?($0)
			}
    }
}
