import UIKit

final class AnyCitySelectionAssembly: Assembly {
	private let selectedCityId: Int?
	private let onSelect: (City) -> Void

	private(set) var scrollView: UIScrollView?

	init(selectedCityId: Int? = nil, onSelect: @escaping (City) -> Void) {
		self.selectedCityId = selectedCityId
		self.onSelect = onSelect
	}

	func make() -> UIViewController {
		let presenter = AnyCitySelectionPresenter(
			qraphQLEndpoint: GraphQLEndpoint(),
			selectedCityId: self.selectedCityId,
			onSelect: self.onSelect
		)
		let controller = CatalogItemSelectionViewController(
			presenter: presenter
		)
		presenter.controller = controller
		self.scrollView = controller.scrollView
		return controller
	}
}
