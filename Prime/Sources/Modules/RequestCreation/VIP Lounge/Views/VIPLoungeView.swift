import SnapKit
import UIKit

extension VIPLoungeView {
    struct Appearance: Codable {
        var cornerRadius: CGFloat = 10
        var backgroundColor = Palette.shared.gray5
        var separatorColor = Palette.shared.gray4
        var primColor = Palette.shared.brandPrimary
    }
}

enum VIPLoungeSegmentTypes: Int {
    case departure
    case arrival
    case both
    
    var title: String {
        switch self {
        case .departure:
            return "avia.segment.departure".localized
        case .arrival:
            return "avia.segment.arrival".localized
        case .both:
            return "avia.segment.both".localized
        }
    }
    
    var titleList: [String] {
        return [
            Self.departure,
            Self.arrival,
            Self.both
        ].map { $0.title }
    }
}

final class VIPLoungeView: ChatKeyboardDismissingView {
    private lazy var headerContainerView = UIView() // пассажиры + маршрут
    private lazy var routeView = AviaRoutePickerView()
    private lazy var passengersView = AviaPassengersPickerView()
    
    private lazy var departureFieldView = AviaPickerFieldView()
    private lazy var arrivalFieldView = AviaPickerFieldView()
    private lazy var hederContainerSeparatorView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = Palette.shared.gray4
        return view
    }()
    
    private lazy var topContainerSeparatorView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = Palette.shared.gray4
        return view
    }()
    
    private lazy var dateContainerView = UIStackView() // с и по даты
    private lazy var singleDatePicker = AviaDatePickerFieldView(dateType: .single)
    private lazy var departureDatePicker = AviaDatePickerFieldView(dateType: .departure)
    private lazy var multiCityView = UIStackView()
    private var segmentType: VIPLoungeSegmentTypes = .departure
    
    private lazy var topContainerView: UIView = {
        return setupTopContainerView()
    }()
    
    private lazy var verticalSeparatorView = {
        let view = UIView()
        view.backgroundColorThemed = appearance.separatorColor
        return view
    }()
    
    private lazy var flightContainerStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }() // маршрут перелетов

    private lazy var borderedSegmentControlView = {
        let segmentControll = BorderedSegmentedControlView()
        segmentControll.setup(
            with: segmentType.titleList,
            color: appearance.primColor
        )
        
        segmentControll.segmentSelectionCallback = { [weak self] selectedIndex in
            
            let type = VIPLoungeSegmentTypes(rawValue: selectedIndex) ?? .departure
            self?.onTapSegmentItem?(type)
            self?.handleSegmentSelection(with: type)
        }
        return segmentControll
    }()
    
    private lazy var stackView: ScrollableStack = {
        let scrollableStack = ScrollableStack(.vertical)
        scrollableStack.backgroundColorThemed = Palette.shared.clear
        return scrollableStack
    }()
    
    private var stackViewTopConstraint: Constraint?
    private let appearance: Appearance
    
    var onPassengersTap: (() -> Void)?
    var onDepartureFieldTap: ((Int) -> Void)?
    var onArrivalFieldTap: ((Int) -> Void)?
    var onSingleDateTap: ((Int) -> Void)?
    var onDepartureDateTap: ((Int) -> Void)?
    
    var onDeleteRow: ((Int) -> Void)?
    var onTapSegmentItem: ((VIPLoungeSegmentTypes) -> Void)?

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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.stackView.backgroundColor = .white
    }
    
    // MARK: - Public methods
    
    func update(_ route: AviaRoute) {
        self.routeView.update(with: route)
        switch route {
        case .oneWay:
            self.stackView.removeArrangedSubviews()
            
            [
                self.topContainerView,
                self.headerContainerView,
                self.flightContainerStackView,
                self.borderedSegmentControlView
            ].forEach(self.stackView.addArrangedSubview)
        default:
            break
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
            break
        }
    }

    func updateSegment(with type: VIPLoungeSegmentTypes) {
        borderedSegmentControlView.segmentedControl.selectedSegmentIndex = type.rawValue
        handleSegmentSelection(with: type)
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
    
    func updateStackTopConstraint(_ offset: ConstraintOffsetTarget) {
        self.stackViewTopConstraint?.update(offset: offset)
    }
    
    // MARK: - Private methods
    
    private func handleSegmentSelection(with type: VIPLoungeSegmentTypes) {
        switch type {
        case .departure:
            self.arrivalFieldView.isHidden = true
            self.departureFieldView.isHidden = false
        case .arrival:
            self.departureFieldView.isHidden = true
            self.arrivalFieldView.isHidden = false
        case .both:
            self.departureFieldView.isHidden = false
            self.arrivalFieldView.isHidden = false
        }
    }
    
    private func setupTopContainerView() -> UIView {
        let view = UIView()
        
        // Create an image view
        let imageView = UIImageView(image: UIImage(named: "vip_lounge_icon"))
        imageView.contentMode = .scaleAspectFit
        
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColorThemed = self.appearance.primColor
        
        let label = UILabel()
        label.text = "createTask.vipLounge".localized
        label.fontThemed = Palette.shared.primeFont.with(size: 15)
        label.textColorThemed = Palette.shared.gray0
        
        view.addSubviews([imageView, label])
        
        imageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.width.equalTo(36)
            make.height.equalTo(36)
            make.centerY.equalToSuperview()
        }
        
        label.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.leading.equalTo(imageView.snp.trailing).offset(10)
            make.centerY.equalTo(imageView.snp.centerY)
        }
        view.addSubviews(topContainerSeparatorView)
        
        self.topContainerSeparatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
        
        return view
    }
    
    private func setupTaps() {
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

extension VIPLoungeView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.layer.cornerRadius = self.appearance.cornerRadius
        
        self.flightContainerStackView.backgroundColorThemed = Palette.shared.gray5
        self.dateContainerView.axis = .horizontal
        self.dateContainerView.spacing = 0
        self.dateContainerView.distribution = .fillEqually
        self.multiCityView.axis = .vertical
        self.arrivalFieldView.isHidden = true
    }
    
    func addSubviews() {
        [
            self.singleDatePicker,
            self.verticalSeparatorView,
            self.passengersView,
            self.hederContainerSeparatorView
        ].forEach(self.headerContainerView.addSubview)
        
        [
            self.departureFieldView,
            self.arrivalFieldView
        ].forEach(self.flightContainerStackView.addArrangedSubview)
        
        [
            self.topContainerView,
            self.headerContainerView,
            self.flightContainerStackView,
            self.borderedSegmentControlView
        ].forEach(self.stackView.addArrangedSubview)
        
        self.dateContainerView.addArrangedSubview(self.departureDatePicker)
        self.addSubview(self.stackView)
    }
    
    func makeConstraints() {
        
        self.stackView.snp.makeConstraints { make in
            self.stackViewTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        self.singleDatePicker.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(self.verticalSeparatorView.snp.leading).offset(-15)
        }
        
        self.verticalSeparatorView.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(30)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        self.passengersView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.lessThanOrEqualTo(self.verticalSeparatorView.snp.trailing).offset(15)
        }
        
        self.departureFieldView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.equalToSuperview().offset(9)
        }
        
        self.arrivalFieldView.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(9)
            make.top.equalTo(self.departureFieldView.snp.bottom)
        }
        
        self.hederContainerSeparatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
        
        self.topContainerView.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        
        self.headerContainerView.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        self.borderedSegmentControlView.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
}
