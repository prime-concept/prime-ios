import Foundation
import PromiseKit

protocol CardsPresenterProtocol: AnyObject {
    func loadCards()
    func openForm(cardIndex: Int)
}

final class CardsPresenter: CardsPresenterProtocol {
    weak var viewController: CardViewControllerProtocol?

    private let tabType: CardsTabType
    private let cardsService: CardsServiceProtocol

    private var cards: [Discount]?

    init(cardsService: CardsServiceProtocol, tabType: CardsTabType) {
        self.cardsService = cardsService
        self.tabType = tabType

        cardsService.subscribeForUpdates(receiver: self) { [weak self] updatedCards in
            self?.updateCards(updatedCards)
        }
    }

    deinit {
        self.cardsService.unsubscribeFromUpdates(receiver: self)
    }

    func loadCards() {
        self.viewController?.showActivity()

        DispatchQueue.global().promise {
            self.cardsService.getDiscountCards()
        }
        .done { [weak self] loyaltyCards in
            self?.updateCards(loyaltyCards)
        }
		.catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) getDiscountCards failed",
					parameters: error.asDictionary
				)
		}

        self.loadCardTypes()
    }

    func loadCardTypes() {
		DispatchQueue.global()
			.promise {
				self.cardsService.getDiscountCardTypes()
			}.catch { error in
				AnalyticsReportingService
					.shared.log(
						name: "[ERROR] \(Swift.type(of: self)) getDiscountCardTypes failed",
						parameters: error.asDictionary
					)
			}
    }

    func openForm(cardIndex: Int) {
        guard let discount = self.cards?[safe: cardIndex] else {
            return
        }

        self.viewController?.presentForm(for: .existing(discount))
    }

    private func updateCards(_ cards: [Discount]) {
        switch self.tabType {
        case .loyalty:
            let viewModel = cards.map(self.tabType.viewModelFactory)
            self.cards = cards
            self.viewController?.update(with: viewModel)
        default:
            let viewModel: [CardsViewModel] = []
            self.cards = []
            self.viewController?.update(with: viewModel)
        }
    }
}
