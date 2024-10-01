import Foundation
import UIKit

final class FamilyTypeSelectionAssembly: Assembly {
    private let selectedType: ContactType?
    private let onSelect: (ContactType) -> Void

    init(selectedType: ContactType?, onSelect: @escaping (ContactType) -> Void) {
        self.selectedType = selectedType
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = FamilyTypeSelectionPresenter(
            selectedType: self.selectedType,
            contactTypes: FamilyService.shared.contactTypes ?? [],
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
