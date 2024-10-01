import RestaurantSDK

struct TaskInput: Encodable {
    let taskTypeId: Int
    var vipLounge: VipLoungeInput?
    var avia: AviaInput?
    var hotel: HotelInput?
	var restaurant: RestaurantSDK.RestaurantInput?
}

struct CreateResponse: Decodable {
    struct Data: Decodable {
        let customer: Customer
    }

    struct Customer: Decodable {
        let task: Task
    }

    struct Task: Decodable {
        let create: Int
    }

    let data: Data

    var taskId: Int {
        self.data.customer.task.create
    }
}
