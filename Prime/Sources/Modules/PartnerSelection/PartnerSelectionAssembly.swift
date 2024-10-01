import UIKit

final class PartnerSelectionAssembly: Assembly {
    private let selectedPartnerId: Int?
    private let onSelect: (Partner) -> Void
	private let partnerTypeId: [Int]
    private(set) var scrollView: UIScrollView?

    init(
		partnerTypeId: [Int],
		selectedPartnerId: Int? = nil,
		onSelect: @escaping (Partner) -> Void
	) {
		self.partnerTypeId = partnerTypeId
        self.selectedPartnerId = selectedPartnerId
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = PartnerSelectionPresenter(
            qraphQLEndpoint: GraphQLEndpoint(),
			partnerTypeId: self.partnerTypeId,
            selectedPartnerId: self.selectedPartnerId,
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
