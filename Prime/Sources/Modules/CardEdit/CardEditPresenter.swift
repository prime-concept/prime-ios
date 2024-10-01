import Foundation
import PromiseKit

extension Notification.Name {
	static let profileCardsChanged = Notification.Name("Profile.Cards.Changed")
}

protocol CardEditPresenterProtocol: AnyObject {
    func loadForm()
    func saveForm()
    func deleteForm()
}

final class CardEditPresenter: CardEditPresenterProtocol {
    weak var viewController: CardEditViewControllerProtocol?

    private var card: Discount
    private let allCards: [Discount]
    private let cardsService: CardsServiceProtocol
    private var newVisaRelatedPassportID: Int?
    private var selectedType: DiscountType
    private var cardTypes: [DiscountType]

    init(card: Discount, allCards: [Discount], cardTypes: [DiscountType], cardsService: CardsServiceProtocol) {
        self.card = card
        self.allCards = allCards
        self.cardsService = cardsService
        self.cardTypes = cardTypes
        self.selectedType =
            .init(
                id: -1,
                name: card.type?.name ?? "",
                position: nil,
                color: nil,
                logoUrl: nil
            )
    }

    func loadForm() {
        self.loadDiscountForm()
    }

    func deleteForm() {
        guard let id = self.card.id else {
            return
        }

        self.viewController?.showActivity()

        DispatchQueue.main.promise {
            self.cardsService.delete(with: id)
        }
        .done { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
			NotificationCenter.default.post(name: .profileCardsChanged, object: nil)
            strongSelf.viewController?.hideActivity()
            strongSelf.viewController?.closeFormWithSuccess()
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) Loyalty Card delete failed",
					parameters: error.asDictionary
				)
            self.viewController?.show(error: Localization.localize("documents.form.commonError"))
        }
    }

    func saveForm() {
        self.viewController?.showActivity()

        let discountValidationField = [
            self.card.cardNumber,
            self.card.type?.name
        ]

        let isValidToSave = discountValidationField.allSatisfy { $0?.isEmpty == false }

        guard isValidToSave else {
            self.viewController?.show(error: Localization.localize("documents.form.validation.error"))
            return
        }

        let queue = DispatchQueue.global()

        queue.promise { () -> Promise<Discount> in
            if self.card.id != nil {
                return self.cardsService.update(discount: self.card)
            } else {
                return self.cardsService.create(discount: self.card)
            }
        }
        .done { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
			NotificationCenter.default.post(name: .profileCardsChanged, object: nil)
            delay(0.5) {
                strongSelf.viewController?.closeFormWithSuccess()
            }
        }
        .catch { error in
			AnalyticsReportingService
				.shared.log(
					name: "[ERROR] \(Swift.type(of: self)) Loyalty Card save failed",
					parameters: error.asDictionary
				)
            self.viewController?.show(error: Localization.localize("documents.form.commonError"))
        }
    }
    // MARK: - Private

    private func loadDebitForm() {
    }

    private func loadDiscountForm() {
        var fields: [CardEditFormField] = []
        let indexType = cardTypes.firstIndex(where: { $0.id == self.card.type?.id })
        fields = [
            .picker(
                CardEditPickerModel(
                    title: "cards.form.field.card.type".localized,
                    values: cardTypes.compactMap(\.name),
                    selectedIndex: indexType,
                    pickerInvoker: { [weak self] in
                        self?.presentTypePicker()
                    }
                )
            ),
            .textField(
                CardEditTextFieldModel(
                    title: "cards.form.field.card.number".localized,
                    placeholder: "cards.form.field.card.number".localized,
                    value: self.card.cardNumber ?? "",
                    isFormatted: false,
                    onUpdate: { [weak self] val in
                        self?.card.cardNumber = val
                    }
                )
            )
        ]

        self.viewController?.update(with: fields)
    }

    private func presentTypePicker() {
        self.viewController?.presentTypesPicker(
            selected: self.selectedType,
            onSelect: { [weak self] type in
                self?.selectedType = type
                self?.card.type = type
                self?.generateUpdatedPricker()
            }
        )
    }

    private func generateUpdatedPricker() {
        let indexType = cardTypes.firstIndex(where: { $0.id == self.card.type?.id })
        let model = CardEditPickerModel(
            title: "cards.form.field.card.type".localized,
            values: cardTypes.compactMap(\.name),
            selectedIndex: indexType,
            pickerInvoker: { [weak self] in
                self?.presentTypePicker()
            }
        )
        self.viewController?.update(with: model)
    }
}
