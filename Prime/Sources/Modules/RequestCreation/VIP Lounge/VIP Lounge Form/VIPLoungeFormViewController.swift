import UIKit

protocol VIPLoungeFormViewControllerProtocol: ModalRouterSourceProtocol, RequestFormViewController {
    var aviaFormView: VIPLoungeView { get }
    
    func update(_ route: AviaRoute)
    func update(_ passengers: AviaPassengerModel)
    func update(_ leg: FlightLeg, with model: AirportPickerViewModel)
    func update(_ date: AviaDatePickerModel, for type: DateType)
    func updateSegment(with type: VIPLoungeSegmentTypes)
    func flip(with model: AviaFlipModel)
    
    func update(_ multiCity: MultiCityViewModel)
    func setup(with multiCity: MultiCityViewModel)
    
    func shouldPinFormToTop(_ should: Bool)
}

final class VIPLoungeFormViewController: UIViewController {
    private enum Constants {
        static let oneWayOrRoundTripHeight = 206
        static let bothTripHeight = 256
        static let multiCityHeight = 246
    }
    
    private lazy var backgroundImageView = with(UIImageView()) { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.image = RequestBackgroundRandomizer.image(
            named: "avia_background",
            range: 1...1
        )
    }
    
    private lazy var formView = VIPLoungeView()
    private let presenter: VIPLoungeFormPresenter
    
    private var shouldPinFormToTop = false
    
    init(presenter: VIPLoungeFormPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.setupActions()
        self.presenter.didLoad()
    }
    
    override func loadView() {
        self.view = ChatKeyboardDismissingView()
    }
    
    private func setupViews() {
        self.view.backgroundColorThemed = Palette.shared.gray5
        
        self.view.addSubview(self.backgroundImageView)
        self.view.addSubview(self.formView)
        
        let grabberView = GrabberView()
        self.view.addSubview(grabberView)
        grabberView.make(.edges(except: .bottom), .equalToSuperview)
        grabberView.make(.height, .equal, 14)
        
        self.backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.85)
        }
        
        self.formView.layer.cornerRadius = 12.0
        self.backgroundImageView.layer.cornerRadius = 12.0
        self.formView.clipsToBounds = true
        self.backgroundImageView.clipsToBounds = true
        
        self.placeDismissRecognizer()
    }

    private func placeDismissRecognizer() {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(_:)))
        panRecognizer.cancelsTouchesInView = false
        
        self.formView.isUserInteractionEnabled = true
        self.formView.addGestureRecognizer(panRecognizer)
    }
    
    @objc
    private func panRecognized(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if translation.y > 20 {
            Notification.post(.messageInputShouldHideKeyboard)
        }
    }
    
    private func setupActions() {

        self.formView.onPassengersTap = { [weak self] in
            self?.presenter.openPassengersSelection()
        }
        self.formView.onDepartureFieldTap = { [weak self] index in
            self?.presenter.selectAirport(for: .departure, at: index)
        }
        self.formView.onArrivalFieldTap = { [weak self] index in
            self?.presenter.selectAirport(for: .arrival, at: index)
        }
        self.formView.onSingleDateTap = { [weak self] index in
            self?.presenter.selectDate(with: .single, at: index)
        }
        self.formView.onDepartureDateTap = { [weak self] index in
            self?.presenter.selectDate(with: .departure, at: index)
        }

        self.formView.onDeleteRow = { [weak self] index in
            self?.presenter.deleteRow(at: index)
        }
        
        self.formView.onTapSegmentItem = { [weak self] type in
            self?.presenter.vipLoungeType = type
            self?.updateConstraints(segments: type)
        }
    }

    func updateSegment(with type: VIPLoungeSegmentTypes) {
        formView.updateSegment(with: type)
        updateConstraints(segments: type)
        view.layoutIfNeeded()
    }

    func updateConstraints(segments type: VIPLoungeSegmentTypes) {
        switch type {
        case .departure, .arrival:
            self.updateFormViewHeightConstraint(with: Constants.oneWayOrRoundTripHeight)
        case .both:
            self.updateFormViewHeightConstraint(with: Constants.bothTripHeight)
        }
    }

    func updateFormViewHeightConstraint(with height: Int? = nil, isFullScreen: Bool = false) {
        var constraintHeight = height
        
        self.formView.snp.remakeConstraints { make in
            if isFullScreen {
                make.edges.equalToSuperview()
                self.formView.updateStackTopConstraint(20)
                return
            }
            
            if height == nil {
                let route = self.presenter.route
                constraintHeight = route == .multiCity ? Constants.multiCityHeight : Constants.oneWayOrRoundTripHeight
            }

            make.height.equalTo(constraintHeight ?? 0).priority(.init(999))
            make.leading.trailing.bottom.equalToSuperview()
            self.formView.updateStackTopConstraint(0)
        }
    }
}

extension VIPLoungeFormViewController: VIPLoungeFormViewControllerProtocol {
    func flip(with model: AviaFlipModel) {}
    
    var aviaFormView: VIPLoungeView {
        self.formView
    }
    
    func update(_ route: AviaRoute) {
        self.formView.update(route)
        self.updateFormViewHeightConstraint(isFullScreen: self.shouldPinFormToTop)
    }
    
    func update(_ passengers: AviaPassengerModel) {
        self.formView.update(passengers)
    }
    
    func update(_ leg: FlightLeg, with model: AirportPickerViewModel) {
        self.formView.update(leg, with: model)
    }
    
    func update(_ date: AviaDatePickerModel, for type: DateType) {
        self.formView.update(date, for: type)
    }
    
    func update(_ multiCity: MultiCityViewModel) {
        self.formView.setup(with: multiCity)
    }
    
    func setup(with multiCity: MultiCityViewModel) {
        self.formView.setup(with: multiCity)
    }
    
    func sendRequest(completion: @escaping (Int?, Error?) -> Void) {
        self.presenter.createTask(completion: completion)
    }
    
    func reset() {}
    
    func shouldPinFormToTop(_ should: Bool) {
        self.shouldPinFormToTop = should
        
        UIView.animate(withDuration: 0) {
            self.updateFormViewHeightConstraint(isFullScreen: should)
        }
    }
}
