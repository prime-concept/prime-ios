import Foundation

protocol CatalogItemSelectionPresenterProtocol {
	func didLoad()
	func search(by string: String)
	func numberOfItems() -> Int
	func item(at index: Int) -> CatalogItemRepresentable
	func select(at index: Int)
	func apply()
}
