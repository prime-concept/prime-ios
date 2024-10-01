import UIKit

struct RequestCreationViewModel {
    let assistant: String?
    let data: [RequestCreationItemViewModel]

    init(
        uncompletedTasks: [Task],
        assistant: String?,
        addTaskAction: ((TaskTypeObject) -> Void)?,
        expandTaskAction: ((RequestBlockItemCreationViewModel, UIView) -> Void)?
    ) {
        self.assistant = assistant

        var data: [RequestCreationItemViewModel] = []

        var aviaTasks: [RequestBlockItemTaskViewModel] = []
        var hotelTasks: [RequestBlockItemTaskViewModel] = []
        var vipTasks: [RequestBlockItemTaskViewModel] = []
        var carTasks: [RequestBlockItemTaskViewModel] = []

        var restaurantTasks: [RequestBlockItemTaskViewModel] = []
        var ticketTasks: [RequestBlockItemTaskViewModel] = []
        var alcoholTasks: [RequestBlockItemTaskViewModel] = []
        var flowerTasks: [RequestBlockItemTaskViewModel] = []

        uncompletedTasks.forEach { task in
            switch task.taskType?.type {
            case .avia:
                aviaTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            case .hotel:
                hotelTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            case .vipLounge:
                vipTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            case .transfer:
                carTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            case .restaurants:
                restaurantTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            case .tickets:
                ticketTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            case .alcohol:
                alcoholTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            case .flowers:
                flowerTasks.append(
                    RequestBlockItemTaskViewModel(
                        title: task.title,
                        subtitle: task.description
                    )
                )
            default:
                break
            }
        }

        let aviaViewModel = RequestBlockItemCreationViewModel(
            data: aviaTasks,
            type: .avia,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let hotelViewModel = RequestBlockItemCreationViewModel(
            data: hotelTasks,
            type: .hotel,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let vipViewModel = RequestBlockItemCreationViewModel(
            data: vipTasks,
            type: .vipLounge,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let carViewModel = RequestBlockItemCreationViewModel(
            data: carTasks,
            type: .transfer,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let restaurantViewModel = RequestBlockItemCreationViewModel(
            data: restaurantTasks,
            type: .restaurants,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let ticketViewModel = RequestBlockItemCreationViewModel(
            data: ticketTasks,
            type: .tickets,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let alcoholViewModel = RequestBlockItemCreationViewModel(
            data: alcoholTasks,
            type: .alcohol,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let flowerViewModel = RequestBlockItemCreationViewModel(
            data: flowerTasks,
            type: .flowers,
            addTaskAction: addTaskAction,
            expandTaskAction: expandTaskAction
        )

        let sortedTravelData = [aviaViewModel, hotelViewModel, vipViewModel, carViewModel]
            .sorted(by: { $0.count > $1.count })

        let sortedLifestyleData = [
            restaurantViewModel,
            ticketViewModel,
            alcoholViewModel,
            flowerViewModel
        ].sorted(by: { $0.count > $1.count })

        let travelData = RequestCreationItemViewModel(
            title: "createTask.travel".localized,
            data: sortedTravelData
        )

        let lifestyleData = RequestCreationItemViewModel(
            title: "createTask.lifestyle".localized,
            data: sortedLifestyleData
        )

        data.append(travelData)
        data.append(lifestyleData)

        self.data = data
    }
}

struct RequestCreationItemViewModel {
    let title: String
    let data: [RequestBlockItemCreationViewModel]
}

struct RequestCreationCategoriesViewModel {
    struct Button {
        let id: Int
        let image: UIImage?
        let title: String
    }
    let topRow: [Button]
    let bottomRow: [Button]
    let selectedId: Int?
    let onCategorySelected: ((Int) -> Void)
}

struct TaskAccessoryHeaderViewModel {
    struct Button {
        let title: String
        let imageName: String?
        let onTap: (() -> Void)
    }
	enum Selected {
		case existing
		case new
	}
    let title: String
	let existingButton: Button
	let newButton: Button
	let selected: Selected
}
