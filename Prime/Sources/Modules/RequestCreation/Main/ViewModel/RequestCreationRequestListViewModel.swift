import ChatSDK

struct RequestCreationRequestListViewModel {
	let banners: [HomeBannerViewModel]
    let requestViewModels: [RequestListItemViewModel]

	init(tasks: [Task], banners: [HomeBannerViewModel]) {
        self.requestViewModels = tasks.map { task in
            return RequestListItemViewModel(task: task)
        }

		self.banners = banners
    }
}
