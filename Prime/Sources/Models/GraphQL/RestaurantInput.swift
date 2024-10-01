struct RestaurantInput: Encodable {
	let dateTime: String
	let id: Int
	let name: String
	let personsCount: Int
	let reservedFor: String
	let tableDisplacementOther: String
	let tablePlace: Int
}
