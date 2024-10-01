import Foundation
import PromiseKit

protocol CardsServiceProtocol: AnyObject {
    func getDiscountCards() -> Promise<[Discount]>
    func getDiscountCardTypes() -> Promise<[DiscountType]>
    func create(discount: Discount) -> Promise<Discount>
    func update(discount: Discount) -> Promise<Discount>
    func delete(with id: Int) -> Promise<Void>

    func subscribeForUpdates(receiver: AnyObject, _ handler: @escaping ([Discount]) -> Void)
    func unsubscribeFromUpdates(receiver: AnyObject)
}

final class CardsService: CardsServiceProtocol {
	// Оставляем shared, но очищаем хранимые данные при разлогине/очистке кэша
    static let shared = CardsService(endpoint: DiscountsEndpoint(authService: LocalAuthService.shared))

    private let endpoint: DiscountsEndpointProtocol

    private(set) var discounts: [Discount]?
    private(set) var discountTypes: [DiscountType]?
    private var subscribers: [ObjectIdentifier: ([Discount]) -> Void] = [:]

    init(endpoint: DiscountsEndpointProtocol) {
        self.endpoint = endpoint

		Notification.onReceive(.loggedOut) { [weak self] _ in
			self?.discounts = nil
			self?.discountTypes = nil
			self?.subscribers = [:]
		}

		Notification.onReceive(.shouldClearCache) { [weak self] _ in
			self?.discounts = nil
			self?.discountTypes = nil
		}
    }

    func subscribeForUpdates(receiver: AnyObject, _ handler: @escaping ([Discount]) -> Void) {
        self.subscribers[ObjectIdentifier(receiver)] = handler
    }

    func unsubscribeFromUpdates(receiver: AnyObject) {
        self.subscribers.removeValue(forKey: ObjectIdentifier(receiver))
    }

	func getDiscountCards() -> Promise<[Discount]> {
		DispatchQueue.global().promise {
			self.endpoint.getDiscountCards().promise
		}
		.map { $0.data ?? [] }
		.get(on: .main) { [weak self] discounts in
			self?.discounts = discounts
			self?.notify()
		}
	}

    func getDiscountCardTypes() -> Promise<[DiscountType]> {
        DispatchQueue.global().promise {
            self.endpoint.getDiscountCardTypes().promise
        }
        .map(\.data)
        .get(on: .main) { [weak self] types in
            self?.discountTypes = types
        }
    }

    func create(discount: Discount) -> Promise<Discount> {
        DispatchQueue.global().promise {
            self.endpoint.create(discount: discount).promise
        }
        .get { [weak self] discount in
            var discounts = self?.discounts ?? []
            discounts.append(discount)

            self?.discounts = discounts
            self?.notify()
        }
    }

    func update(discount: Discount) -> Promise<Discount> {
        guard let id = discount.id else {
			return .init(error: Endpoint.Error(.requestRejected, details: "invalidId"))
        }

        return DispatchQueue.global().promise {
            self.endpoint.update(id: id, discount: discount).promise
        }
        .get { [weak self] discount in
            var discounts = self?.discounts ?? []

            for i in 0..<discounts.count where discounts[i].id == discount.id {
                discounts[i] = discount
            }

            self?.discounts = discounts
            self?.notify()
        }
    }

    func delete(with id: Int) -> Promise<Void> {
        DispatchQueue.global().promise {
            self.endpoint.removeCard(with: id).promise
        }
        .map { _ in () }
        .get { [weak self] in
            let discounts = self?.discounts ?? []
            self?.discounts = discounts.filter { $0.id != id }
            self?.notify()
        }
    }

    private func notify() {
        guard let discounts = self.discounts else {
            return
        }

        self.subscribers.forEach { $0.value(discounts) }
    }
}
