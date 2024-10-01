import UIKit

protocol HotelFormViewControllerProtocol: ModalRouterSourceProtocol, RequestFormViewController {
    func setupPlaceOfResidence(_ place: HotelFormRowViewModel)
    func setupDates(_ dates: HotelFormRowViewModel)
    func setupGuests(_ guests: HotelFormRowViewModel)
}

final class HotelFormViewController: UIViewController {
    private lazy var backgroundImageView = with(UIImageView()) { imageView in
        imageView.contentMode = .scaleAspectFill
		imageView.image = RequestBackgroundRandomizer.image(
			named: "hotel_background",
			range: 1...1
		)
    }

    private lazy var formView = HotelFormView()
    private let presenter: HotelFormPresenterProtocol

    init(presenter: HotelFormPresenterProtocol) {
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

    // MARK: - Helpers

    private func setupViews() {
        self.view.addSubview(self.backgroundImageView)
        self.view.addSubview(self.formView)

        let grabberView = GrabberView()
        self.view.addSubview(grabberView)
        grabberView.make(.edges(except: .bottom), .equalToSuperview)
        grabberView.make(.height, .equal, 14)

        self.backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.formView.snp.makeConstraints { make in
            make.height.equalTo(100).priority(.init(999))
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupActions() {
        self.formView.onPlaceTap = { [weak self] in
            self?.presenter.selectPlaceOfResidence()
        }
        self.formView.onDatesTap = { [weak self] in
            self?.presenter.selectDates()
        }
        self.formView.onGuestsTap = { [weak self] in
            self?.presenter.openGuestsSelection()
        }
    }
}

extension HotelFormViewController: HotelFormViewControllerProtocol {
    func sendRequest(completion: @escaping (Int?, Error?) -> Void) {
        self.presenter.createTask(completion: completion)
    }

    func reset() {}

    func setupPlaceOfResidence(_ place: HotelFormRowViewModel) {
        self.formView.setupPlace(place)
    }

    func setupDates(_ dates: HotelFormRowViewModel) {
        self.formView.setupDates(dates)
    }

    func setupGuests(_ guests: HotelFormRowViewModel) {
        self.formView.setupGuests(guests)
    }
}
