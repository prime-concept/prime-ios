import UIKit

final class AviaPassengersAssembly: Assembly {
    let onSelect: (AviaPassengerModel) -> Void
    let passengers: AviaPassengerModel

    init(
        passengers: AviaPassengerModel,
        onSelect: @escaping (AviaPassengerModel) -> Void
    ) {
        self.passengers = passengers
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = AviaPassengersPresenter(passengers: self.passengers, onSelect: self.onSelect)
        let controller = AviaPassengersViewController(presenter: presenter)
        presenter.viewController = controller
        return controller
    }
}
