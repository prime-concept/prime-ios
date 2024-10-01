import Foundation

protocol AviaPassengersPresenterProtocol: AnyObject {
    func loadForm()
    func saveForm()
    func resetForm()
}

final class AviaPassengersPresenter: AviaPassengersPresenterProtocol {
    weak var viewController: AviaPassengersViewControllerProtocol?
    private var passengers: AviaPassengerModel

    let onSelect: (AviaPassengerModel) -> Void

    init(passengers: AviaPassengerModel, onSelect: @escaping (AviaPassengerModel) -> Void) {
        self.passengers = passengers
        self.onSelect = onSelect
    }

    func loadForm() {
        var fields: [AviaPassengerFormField] = []
        fields = [
            .ageView(
                AviaPassengerAgeViewModel(
                    type: .adults,
                    value: self.passengers.adults,
                    onUpdate: { [weak self] val in
                        self?.passengers.adults = val
                    }
                )
            ),
            .ageView(
                AviaPassengerAgeViewModel(
                    type: .children,
                    value: self.passengers.children,
                    onUpdate: { [weak self] val in
                        self?.passengers.children = val
                    }
                )
            ),
            .ageView(
                AviaPassengerAgeViewModel(
                    type: .infants,
                    value: self.passengers.infants,
                    onUpdate: { [weak self] val in
                        self?.passengers.infants = val
                    }
                )
            ),
            .classEmptyView("avia.passengers.modal.class".localized),
            .classView(
                AviaPassengerClassViewModel(
                    title: "avia.passengers.modal.class.business".localized,
                    isSelected: self.passengers.isBusinessSelected,
                    onUpdate: { isSelected in
                        self.passengers.isBusinessSelected = isSelected
                        self.loadForm()
                    }
                )
            ),
            .classView(
                AviaPassengerClassViewModel(
                    title: "avia.passengers.modal.class.economy".localized,
                    isSelected: !self.passengers.isBusinessSelected,
                    onUpdate: { isSelected in
                        self.passengers.isBusinessSelected = !isSelected
                        self.loadForm()
                    }
                )
            )
        ]

        self.viewController?.update(with: fields)
    }

    func saveForm() {
        self.onSelect(self.passengers)
        self.viewController?.closeFormWithSuccess()
    }

    func resetForm() {
        self.passengers = .default
        self.loadForm()
    }
}

struct AviaPassengerModel {
    var adults: Int
    var children: Int
    var infants: Int
    var isBusinessSelected: Bool
    var isShowOnlyPassengers: Bool = false

    static var `default`: Self {
        .init(
            adults: 1,
            children: 0,
            infants: 0,
            isBusinessSelected: true
        )
    }
    
    static var vipLounge: Self {
        .init(
            adults: 1,
            children: 0,
            infants: 0,
            isBusinessSelected: true,
            isShowOnlyPassengers: true
        )
    }

    var total: Int {
        adults + children + infants
    }
    
    var passengerTitle: String {
        return "avia.passenger".pluralized(total)
    }

    var `class`: String {
        let business = "avia.passengers.modal.class.business".localized
        let economy = "avia.passengers.modal.class.economy".localized
        return isBusinessSelected ? business : economy
    }
}
