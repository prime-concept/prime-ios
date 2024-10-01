import ChatSDK

struct CompletedTasksListViewModel {
	var headerItemViewModels: [CompletedTasksListHeaderItemViewModel] = []
    var completedTaskViewModels: [CompletedTaskViewModel] = []

	private let filters: [TaskTypeFilter] = TaskTypeEnumeration.allCases.compactMap {
		TaskTypeEnumeration.filter(for: $0)
	}

    init(
        tasks: [Task],
        listType: TasksListType,
		filterBy filteringType: TaskTypeEnumeration? = .all,
        onTapOrder: @escaping (URL?) -> Void = { _ in return }
    ) {
		var complexFilter: TaskTypeFilter? = filteringType != nil
			? TaskTypeEnumeration.filter(for: filteringType!)
			: nil
        
		if listType == .completed || listType == .all {
            let allTasksCount = tasks.count
            var othersCount = allTasksCount

            let allFilterViewModel = CompletedTasksListHeaderItemViewModel(
                type: .all,
                count: allTasksCount
            )
            self.headerItemViewModels.append(allFilterViewModel)
			
			self.filters.forEach { filter in
				let filteredTasksCount = tasks.filter {
					if let type = $0.taskType?.type {
						return filter.contains(type)
					}
					return false
				}.count
                othersCount -= filteredTasksCount
                guard filteredTasksCount != 0 else {
                    return
                }

                let headerViewModel = CompletedTasksListHeaderItemViewModel(
                    type: filter[0],
                    count: filteredTasksCount
                )
                self.headerItemViewModels.append(headerViewModel)
            }

            self.headerItemViewModels.sort(by: { $0.count > $1.count })

            if othersCount != 0 {
                let othersFilterViewModel = CompletedTasksListHeaderItemViewModel(
                    type: .others,
                    count: othersCount
                )
                self.headerItemViewModels.append(othersFilterViewModel)
            }

            if let filter = complexFilter,
               let selectedIndex = self.headerItemViewModels
				.firstIndex(where: { filter.contains($0.type) }) {
                self.headerItemViewModels[selectedIndex].isSelected = true
            } else if !self.headerItemViewModels.isEmpty {
				complexFilter = TaskTypeEnumeration.filter(for: self.headerItemViewModels[0].type)
                self.headerItemViewModels[0].isSelected = true
            }
        }

        self.completedTaskViewModels = tasks.flatMap { task -> [CompletedTaskViewModel] in
            if listType == .waitingForPayment {
                return task.ordersWaitingForPayment.map {
                    CompletedTaskViewModel(
                        task: task,
                        type: listType,
                        order: $0,
                        onTapOrder: onTapOrder
                    )
                }
            }
			if filteringType == .all {
				let item = CompletedTaskViewModel(task: task, type: listType)
				return [item]
			}

			let type = task.taskType?.type
			if filteringType == .others && self.filters.allSatisfy({
				if let type = type { return !$0.contains(type) }
				return true
			}) {
				let item = CompletedTaskViewModel(task: task, type: listType)
				return [item]
			}

			guard let type = task.taskType?.type, (complexFilter?.contains(type))^ else {
				return []
			}
			let item = CompletedTaskViewModel(task: task, type: listType)
			return [item]
        }.sorted(by: { first, second in
            switch listType {
            case .waitingForPayment:
                guard let firstDueDate = first.order?.dueDate,
                      let secondDueDate = second.order?.dueDate else {
                    return false
                }
                return firstDueDate.compare(secondDueDate) == .orderedAscending
			case .completed, .all:
                guard let firstDate = Date(string: first.task.startServiceDate ?? first.task.date),
                      let secondDate = Date(string: second.task.startServiceDate ?? second.task.date) else {
                    return false
                }
                return firstDate > secondDate
            }
        })
    }
}
