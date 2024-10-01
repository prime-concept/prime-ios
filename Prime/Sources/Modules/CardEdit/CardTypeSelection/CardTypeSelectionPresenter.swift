import Foundation

final class CardTypeSelectionPresenter: CatalogItemSelectionPresenterProtocol {
    weak var controller: CatalogItemSelectionControllerProtocol?

    private var selectedType: DiscountType?
    private let onSelect: ((DiscountType) -> Void)
    private var cardTypes: [DiscountType]
    private var filteredTypes: [DiscountType] = []
    private var search: String?

    init(
        selectedType: DiscountType?,
        cardTypes: [DiscountType],
        onSelect: @escaping ((DiscountType) -> Void)
    ) {
        self.selectedType = selectedType
        self.cardTypes = cardTypes
        self.onSelect = onSelect
    }

    func didLoad() {
        self.filteredTypes = self.cardTypes
        self.controller?.reload()
    }

    func search(by string: String) {
        self.search = string

        if string.isEmpty {
            self.filteredTypes = self.cardTypes
        } else {
            self.filteredTypes = self.cardTypes.filter {
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
        return CardTypesViewModel(name: type.name ?? "", selected: type == self.selectedType )
    }

    func select(at index: Int) {
        self.selectedType = filteredTypes[index]
    }

    func apply() {
        self.selectedType.flatMap { self.onSelect($0) }
    }

    // MARK: - Private

//    private func normalizeSelectedCountry() {
//        guard let fakeType = self.selectedType, fakeType.id == -1 else {
//            return
//        }
//
//        self.selectedType = self.cardTypes.first { type in
//            type.name == fakeType.name
//        }
//    }
}

struct CardTypesViewModel {
    let name: String
    let selected: Bool
}

extension CardTypesViewModel: CatalogItemRepresentable {
    var description: String? {
        nil
    }
}
