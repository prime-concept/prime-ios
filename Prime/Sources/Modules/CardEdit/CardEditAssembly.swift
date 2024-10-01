import UIKit

final class CardEditAssembly: Assembly {
    private(set) var scrollView: UIScrollView?
    private let type: FormType

    init(type: FormType = .newDiscount) {
        self.type = type
    }

    func make() -> UIViewController {
        let discount: Discount
        let canDelete: Bool

        switch type {
        case .newDiscount:
            discount = Discount()
            canDelete = false
        case .newCard:
            discount = Discount()
            canDelete = false
        case .existing(let card):
            discount = card
            canDelete = true
        }
        let presenter = CardEditPresenter(
            card: discount,
            allCards: CardsService.shared.discounts ?? [],
            cardTypes: CardsService.shared.discountTypes ?? [],
            cardsService: CardsService.shared
        )
        let controller = CardEditViewController(presenter: presenter, canDelete: canDelete)
        presenter.viewController = controller
        self.scrollView = controller.scrollView
        return controller
    }


    enum FormType {
        case existing(Discount)
        case newCard
        case newDiscount
    }
}
