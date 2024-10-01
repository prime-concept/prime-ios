import UIKit

final class CardTypeSelectionAssembly: Assembly {
    private let selectedType: DiscountType?
    private let onSelect: (DiscountType) -> Void

    init(selectedType: DiscountType?, onSelect: @escaping (DiscountType) -> Void) {
        self.selectedType = selectedType
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = CardTypeSelectionPresenter(
            selectedType: self.selectedType,
            cardTypes: CardsService.shared.discountTypes ?? [],
            onSelect: self.onSelect
        )
        let controller = CatalogItemSelectionViewController(
            presenter: presenter
        )
        controller.modalPresentationStyle = .popover
        controller.modalTransitionStyle = .coverVertical
        presenter.controller = controller
        return controller
    }
}
