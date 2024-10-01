import Foundation

protocol CatalogItemRepresentable {
	var name: String { get }
	var description: String? { get }
	var selected: Bool { get }
}
