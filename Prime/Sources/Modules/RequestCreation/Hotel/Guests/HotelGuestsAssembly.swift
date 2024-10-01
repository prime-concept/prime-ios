import UIKit

final class HotelGuestsAssembly: Assembly {
    let onSelect: (HotelGuests) -> Void
    let guests: HotelGuests

    init(
        guests: HotelGuests,
        onSelect: @escaping (HotelGuests) -> Void
    ) {
        self.guests = guests
        self.onSelect = onSelect
    }

    func make() -> UIViewController {
        let presenter = HotelGuestsPresenter(
            guests: self.guests,
            onSelect: self.onSelect
        )
        let controller = HotelGuestsViewController(presenter: presenter)
        presenter.viewController = controller
        return controller
    }
}
