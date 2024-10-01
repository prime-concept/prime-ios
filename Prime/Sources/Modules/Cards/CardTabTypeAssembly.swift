import UIKit

final class CardTabTypeAssembly: Assembly {
    private let tabType: CardsTabType
    private let shouldOpenInCreationMode: Bool

    init(tabType: CardsTabType, shouldOpenInCreationMode: Bool = false) {
        self.tabType = tabType
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
    }

    func make() -> UIViewController {
        let presenter = CardsPresenter(
            cardsService: CardsService.shared,
            tabType: tabType
        )
        let viewController = CardViewController(
            presenter: presenter,
            tabType: tabType,
            shouldOpenInCreationMode: shouldOpenInCreationMode
        )
        presenter.viewController = viewController
        return viewController
    }
}
