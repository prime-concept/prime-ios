// swiftlint:disable all
import UIKit

final class CardsAssembly: Assembly {
    private let indexToMove: Int
    private let shouldOpenInCreationMode: Bool

    init(indexToMove: Int = 0, shouldOpenInCreationMode: Bool = false) {
        self.indexToMove = indexToMove
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
    }

    func make() -> UIViewController {
        var viewControllers: [UIViewController] = []
		for tabType in [CardsTabType.loyalty] {
            let isChoosen = (tabType.typeIndex == indexToMove && shouldOpenInCreationMode)
            viewControllers.append(
                CardTabTypeAssembly(
                    tabType: tabType,
                    shouldOpenInCreationMode: isChoosen
                ).make()
            )
        }
        
        return CardsViewController(
            controllers: viewControllers,
            indexToMove: indexToMove
        )
    }
}

enum CardsTabType: CaseIterable {
    case loyalty
    case payment

    var l10nType: String {
        switch self {
        case .loyalty:
            return "loyalty"
        case .payment:
            return "payment"
        }
    }

    var typeIndex: Int {
        switch self {
        case .loyalty:
            return 0
        case .payment:
            return 1
        }
    }
    var viewModelFactory: (Discount) -> CardsViewModel {
        return CardsViewModel.makeAsLoyalty(from:)
    }

    var createFormType: CardEditAssembly.FormType {
        switch self {
        case .payment:
            return .newCard
        case .loyalty:
            return .newDiscount
        }
    }
}
