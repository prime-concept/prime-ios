import UIKit

final class CountrySelectionAssembly: Assembly {
    private let selectedCountry: Country?
    private let onSelect: (Country) -> Void

    private(set) var scrollView: UIScrollView?

    init(selectedCountry: Country?, onSelect: @escaping (Country) -> Void) {
        self.selectedCountry = selectedCountry
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = CountrySelectionPresenter(
            qraphQLEndpoint: GraphQLEndpoint(),
            selectedCountry: self.selectedCountry,
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
