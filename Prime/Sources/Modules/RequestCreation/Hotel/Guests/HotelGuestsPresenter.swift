import Foundation

protocol HotelGuestsPresenterProtocol: AnyObject {
    func loadForm()

    func add(to field: HotelGuestsRowViewModel.Field)
    func subtract(from field: HotelGuestsRowViewModel.Field)

    func incrementAge(of child: HotelGuestsChildRowViewModel)
    func decrementAge(of child: HotelGuestsChildRowViewModel)

    func saveForm()
    func resetForm()
}

final class HotelGuestsPresenter: HotelGuestsPresenterProtocol {
    weak var viewController: HotelGuestsViewControllerProtocol?
    private var guests: HotelGuests

    let onSelect: (HotelGuests) -> Void

    init(guests: HotelGuests, onSelect: @escaping (HotelGuests) -> Void) {
        self.guests = guests
        self.onSelect = onSelect
    }

    func loadForm() {
        let field = HotelGuestsRowViewModel.Field.self
        var fields: [HotelGuestsFormField] = [
            .rowView(
                HotelGuestsRowViewModel(
                    field: .adults,
                    title: "hotel.guests.adults".localized,
                    isSubtractionEnabled: self.guests.adults > field.adults.minimumAmount,
                    count: self.guests.adults
                )
            ),
            .rowView(
                HotelGuestsRowViewModel(
                    field: .children,
                    title: "hotel.guests.children".localized,
                    isSubtractionEnabled: self.guests.children.amount > field.children.minimumAmount,
                    count: self.guests.children.amount
                )
            ),
            .rowView(
                HotelGuestsRowViewModel(
                    field: .rooms,
                    title: "hotel.guests.rooms".localized,
                    isSubtractionEnabled: self.guests.rooms > field.rooms.minimumAmount,
                    count: self.guests.rooms
                )
            )
        ]

        if self.guests.children.amount > 0 {
            fields.append(
                .headerView("hotel.guests.ages.of.children".localized)
            )
        }

        self.guests.children.ages.enumerated().forEach { iterator in
            let age = iterator.element
            fields.append(
                .childRowView(
                    HotelGuestsChildRowViewModel(
                        isSubtractionEnabled: age > 0,
                        index: iterator.offset,
                        age: age
                    )
                )
            )
        }

        self.viewController?.setup(with: fields)
    }

    func add(to field: HotelGuestsRowViewModel.Field) {
        let amount: Int
        switch field {
        case .adults:
            self.guests.adults += 1
            amount = self.guests.adults
        case .children:
            if self.guests.children.amount == 0 {
                self.viewController?.addChildrenSectionHeader(
                    with: "hotel.guests.ages.of.children".localized
                )
            }

            self.guests.children.ages.append(0)
            let childField: HotelGuestsFormField = .childRowView(
                HotelGuestsChildRowViewModel(
                    isSubtractionEnabled: false,
                    index: self.guests.children.ages.endIndex - 1,
                    age: 0
                )
            )
            self.viewController?.add(child: childField)
            amount = self.guests.children.amount
        case .rooms:
            self.guests.rooms += 1
            amount = self.guests.rooms
        }
        self.viewController?.update(
            field,
            by: amount,
            isEnabled: true
        )
    }

    func subtract(from field: HotelGuestsRowViewModel.Field) {
        let amount: Int
        let isEnabled: Bool
        switch field {
        case .adults:
            self.guests.adults -= 1
            amount = self.guests.adults
        case .children:
            self.guests.children.ages.removeLast()
            self.viewController?.removeLastField()
            amount = self.guests.children.amount

            // Remove children section header
            if amount == 0 {
                self.viewController?.removeLastField()
            }
        case .rooms:
            self.guests.rooms -= 1
            amount = self.guests.rooms
        }
        isEnabled = amount > field.minimumAmount
        self.viewController?.update(
            field,
            by: amount,
            isEnabled: isEnabled
        )
    }

    func incrementAge(of child: HotelGuestsChildRowViewModel) {
        self.guests.children.ages[child.index] += 1
        self.viewController?.update(child, by: self.guests.children.ages[child.index], isEnabled: true)
    }

    func decrementAge(of child: HotelGuestsChildRowViewModel) {
        self.guests.children.ages[child.index] -= 1
        self.viewController?.update(
            child,
            by: self.guests.children.ages[child.index],
            isEnabled: self.guests.children.ages[child.index] > 0
        )
    }

    func saveForm() {
        self.onSelect(self.guests)
        self.viewController?.closeFormWithSuccess()
    }

    func resetForm() {
        self.guests = .default
        self.loadForm()
    }
}
