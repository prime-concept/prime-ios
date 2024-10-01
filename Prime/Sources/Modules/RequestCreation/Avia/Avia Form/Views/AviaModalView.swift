import Foundation
import SnapKit
import UIKit

extension AviaModalView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var separatorColor = Palette.shared.gray4

        var cornerRadius: CGFloat = 10
    }
}

final class AviaModalView: ChatKeyboardDismissingView {
    private lazy var headerContainerView = UIView() //пассажиры + маршрут
    private lazy var routeView = AviaRoutePickerView()
    private lazy var passengersView = AviaPassengersPickerView()

    private lazy var flightContainerView = UIView() //маршрут перелетов
    private lazy var departureFieldView = AviaPickerFieldView()
    private lazy var arrivalFieldView = AviaPickerFieldView()
    private lazy var flipView = AviaFlipView()

    private lazy var dateContainerView = UIStackView() // с и по даты
    private lazy var singleDatePicker = AviaDatePickerFieldView(dateType: .single)
    private lazy var departureDatePicker = AviaDatePickerFieldView(dateType: .departure)
    private lazy var returnDatePicker = AviaDatePickerFieldView(dateType: .return)

    private lazy var multiCityView = UIStackView()
    private lazy var addFlightButton = AddFlightButton()

    private lazy var stackView: ScrollableStack = {
        let scrollableStack = ScrollableStack(.vertical)
        scrollableStack.backgroundColorThemed = Palette.shared.clear
        return scrollableStack
    }()

    private var stackViewTopConstraint: Constraint?
    private let appearance: Appearance

    var onRouteTap: (() -> Void)?
    var onPassengersTap: (() -> Void)?
    var onFlipTap: (() -> Void)?
    var onDepartureFieldTap: ((Int) -> Void)?
    var onArrivalFieldTap: ((Int) -> Void)?
    var onSingleDateTap: ((Int) -> Void)?
    var onDepartureDateTap: ((Int) -> Void)?
    var onReturnDateTap: ((Int) -> Void)?

    var onAddFlight: (() -> Void)?
    var onDeleteRow:((Int) -> Void)?

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)

        // Designable methods
        self.setupView()
        self.addSubviews()
        self.makeConstraints()

        self.setupTaps()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func update(_ route: AviaRoute) {
        self.routeView.update(with: route)
        switch route {
        case .oneWay:
            self.stackView.removeArrangedSubviews()

            [
                self.headerContainerView,
                self.flightContainerView,
                self.singleDatePicker
            ].forEach(self.stackView.addArrangedSubview)
        case .roundTrip:
            self.stackView.removeArrangedSubviews()

            [
                self.headerContainerView,
                self.flightContainerView,
                self.dateContainerView
            ].forEach(self.stackView.addArrangedSubview)
        case .multiCity:
            self.stackView.removeArrangedSubviews()

            self.stackView.addArrangedSubview(self.headerContainerView)
            self.stackView.addArrangedSubviews(self.multiCityView)
            self.stackView.addArrangedSubview(self.addFlightButton)
        }
    }

    func update(_ passengers: AviaPassengerModel) {
        self.passengersView.setup(with: passengers)
    }

    func update(_ leg: FlightLeg, with model: AirportPickerViewModel) {
        if leg == .departure {
            self.departureFieldView.setup(with: model)
        } else {
            self.arrivalFieldView.setup(with: model)
        }
    }

    func update(_ date: AviaDatePickerModel, for type: DateType) {
        switch type {
        case .single:
            self.singleDatePicker.setup(with: date)
        case .departure:
            self.departureDatePicker.setup(with: date)
        case .return:
            self.returnDatePicker.setup(with: date)
        }
    }

    func setup(with multiCity: MultiCityViewModel) {
        switch multiCity.mode {
        case .edit:
            self.multiCityView.removeArrangedSubviews()

            multiCity.rows.enumerated().forEach { row in
                let rowView = AviaMultiCityRowView()
                rowView.onDepartureFieldTap = { [weak self] in
                    self?.onDepartureFieldTap?(row.offset)
                }
                rowView.onArrivalFieldTap = { [weak self] in
                    self?.onArrivalFieldTap?(row.offset)
                }
                rowView.onDateTap = { [weak self] in
                    self?.onSingleDateTap?(row.offset)
                }
                rowView.onDelete = { [weak self] in
                    self?.onDeleteRow?(row.offset)
                }
                rowView.setup(with: row.element)
                self.multiCityView.addArrangedSubview(rowView)
            }
        case .update(let index):
            if let rowView = self.multiCityView.arrangedSubviews[index] as? AviaMultiCityRowView {
                rowView.setup(with: multiCity.rows[index])
            }
        }
    }

    func flip(with model: AviaFlipModel) {
        self.flipView.setup(with: model)
    }

    func updateStackTopConstraint(_ offset: ConstraintOffsetTarget) {
        self.stackViewTopConstraint?.update(offset: offset)
    }

    // MARK: - Private methods

    private func setupTaps() {
        self.routeView.addTapHandler { [weak self] in
            self?.onRouteTap?()
        }
        self.flipView.addTapHandler { [weak self] in
            self?.onFlipTap?()
        }
        self.passengersView.addTapHandler { [weak self] in
            self?.onPassengersTap?()
        }
        self.departureFieldView.addTapHandler { [weak self] in
            self?.onDepartureFieldTap?(0)
        }
        self.arrivalFieldView.addTapHandler { [weak self] in
            self?.onArrivalFieldTap?(0)
        }
        self.singleDatePicker.addTapHandler { [weak self] in
            self?.onSingleDateTap?(0)
        }
        self.departureDatePicker.addTapHandler { [weak self] in
            self?.onDepartureDateTap?(0)
        }
        self.returnDatePicker.addTapHandler { [weak self] in
            self?.onReturnDateTap?(0)
        }
        self.addFlightButton.addTapHandler(feedback: .scale) { [weak self] in
            self?.onAddFlight?()
        }
    }

    private func placeSeparator(on view: UIView) {
        let separator = UIView()
        separator.backgroundColorThemed = self.appearance.separatorColor
        view.addSubview(separator)

        separator.snp.remakeConstraints { make in
            make.width.equalTo(1 / UIScreen.main.scale)
            make.height.equalTo(30)
            make.centerY.leading.equalToSuperview()
        }
    }
}

extension AviaModalView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor

        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.layer.cornerRadius = self.appearance.cornerRadius

        self.flightContainerView.backgroundColorThemed = Palette.shared.gray5
        self.dateContainerView.axis = .horizontal
        self.dateContainerView.spacing = 0
        self.dateContainerView.distribution = .fillEqually
        self.placeSeparator(on: self.returnDatePicker)
        self.multiCityView.axis = .vertical
    }

    func addSubviews() {
        [
            self.routeView,
            self.passengersView
        ].forEach(self.headerContainerView.addSubview)

        [
            self.departureFieldView,
            self.arrivalFieldView,
            self.flipView
        ].forEach(self.flightContainerView.addSubview)

        [
            self.headerContainerView,
            self.flightContainerView
        ].forEach(self.stackView.addArrangedSubview)

        [
            self.departureDatePicker,
            self.returnDatePicker
        ].forEach(self.dateContainerView.addArrangedSubview)

        self.addSubview(self.stackView)
    }

    func makeConstraints() {
        self.stackView.snp.makeConstraints { make in
            self.stackViewTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.routeView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(self.passengersView.snp.leading).offset(-10)
        }

        self.passengersView.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
        }

        self.departureFieldView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.equalTo(self.flipView.snp.leading).offset(9)
        }

        self.arrivalFieldView.snp.makeConstraints { make in
            make.trailing.leading.bottom.equalToSuperview()
            make.top.equalTo(self.departureFieldView.snp.bottom)
            self.arrivalFieldView.updateLabelsStackTrailing(-60)
        }

        self.flipView.snp.makeConstraints() { make in
            make.height.equalTo(55)
            make.width.equalTo(44)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(4)
        }
    }
}
