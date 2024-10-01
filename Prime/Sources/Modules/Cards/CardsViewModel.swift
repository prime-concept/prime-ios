struct CardsViewModel {
    let cardId: String
    let image: String
    let background: String
}

extension CardsViewModel {
    static func makeAsLoyalty(from card: Discount) -> CardsViewModel {
        let id = card.cardNumber ?? ""
        let image = card.type?.logoUrl ?? ""
        let background = card.type?.color ?? ""
        return CardsViewModel(cardId: id, image: image, background: background)
    }
}
