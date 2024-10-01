import Foundation

final class FamilyTypeSelectionPresenter: CatalogItemSelectionPresenterProtocol {
    weak var controller: CatalogItemSelectionControllerProtocol?

    private var selectedType: ContactType?
    private let onSelect: ((ContactType) -> Void)
    private var contactTypes: [ContactType]
    private var filteredTypes: [ContactType] = []
    private var search: String?

    init(
        selectedType: ContactType?,
        contactTypes: [ContactType],
        onSelect: @escaping ((ContactType) -> Void)
    ) {
        self.selectedType = selectedType
        self.contactTypes = contactTypes
        self.onSelect = onSelect
    }

    func didLoad() {
        self.filteredTypes = self.contactTypes
        self.controller?.reload()
    }

    func search(by string: String) {
        self.search = string

        if string.isEmpty {
            self.filteredTypes = self.contactTypes
        } else {
            self.filteredTypes = self.contactTypes.filter {
                $0.name?.range(of: string, options: .caseInsensitive) != nil
            }
        }
        self.controller?.reload()
    }

    func numberOfItems() -> Int {
        self.filteredTypes.count
    }

    func item(at index: Int) -> CatalogItemRepresentable {
        let type = self.filteredTypes[index]
        return FamilyTypesViewModel(name: type.name ?? "", selected: type == self.selectedType )
    }

    func select(at index: Int) {
        self.selectedType = filteredTypes[index]
    }

    func apply() {
        self.selectedType.flatMap { self.onSelect($0) }
    }

}

struct FamilyTypesViewModel {
    let name: String
    let selected: Bool
}
extension FamilyTypesViewModel: CatalogItemRepresentable {
    var description: String? {
        nil
    }
}
