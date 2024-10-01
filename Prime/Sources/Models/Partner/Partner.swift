import Foundation

struct Partner: Codable, Equatable {
	let id: Int
	let name: String
	let address: String?
}


struct PartnersResponse: Codable {
	let data: [String: [Partner]]?
	var partners: [Partner] {
		data?["partners"] ?? []
	}
}
