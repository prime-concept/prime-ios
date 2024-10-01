
import Foundation

struct CrossSaleResponse: Codable {
    let data: CrossSale
}

struct CrossSale: Codable {
    let viewer: Viewer
}

struct Viewer: Codable {
    let taskTypesWithRelated: [TaskTypesWithRelated]
}

struct TaskTypesWithRelated: Codable {
    let id: Int
    let name: String
    let related: [Related]
}

struct Related: Codable {
    let id: Int
    let name: String
}
