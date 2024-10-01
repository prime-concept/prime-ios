import UIKit

final class DocumentsAssembly: Assembly {
    private let indexToMove: Int
    private let shouldOpenInCreationMode: Bool

    init(indexToMove: Int = 0, shouldOpenInCreationMode: Bool = false) {
        self.indexToMove = indexToMove
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
    }

    func make() -> UIViewController {
        var viewControllers: [UIViewController] = []
        for tabType in DocumentTabType.allCases {
            let isChoosen = (tabType.typeIndex == indexToMove && shouldOpenInCreationMode)
            viewControllers.append(
                DocumentTabTypeAssembly(
                    tabType: tabType,
                    shouldOpenInCreationMode: isChoosen
                ).make()
            )
        }

        return DocumentsViewController(
            controllers: viewControllers,
            indexToMove: indexToMove
        )
    }
}

enum DocumentTabType: CaseIterable {
    case passports
    case visas

    var l10nType: String {
        switch self {
        case .passports:
            return "passport"
        case .visas:
            return "visa"
        }
    }

    var typeIndex: Int {
        switch self {
        case .passports:
            return 0
        case .visas:
            return 1
        }
    }

    var documentTypes: [DocumentType] {
        switch self {
        case .passports:
            return [.passport]
        case .visas:
            return [.visa]
        }
    }

    var viewModelFactory: (Document) -> DocumentViewModel {
        switch self {
        case .passports:
            return DocumentViewModel.makeAsPassport(from:)
        case .visas:
            return DocumentViewModel.makeAsVisa(from:)
        }
    }

    var createFormType: DocumentEditAssembly.FormType {
        switch self {
        case .passports:
            return .newPassport
        case .visas:
            return .newVisa
        }
    }
}
