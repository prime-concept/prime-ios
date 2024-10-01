import UIKit

extension HotelFormView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var separatorColor = Palette.shared.gray3

        var cornerRadius: CGFloat = 10
    }
}

final class HotelFormView: UIView {
    private lazy var stackView = with(ScrollableStack(.vertical)) {
        $0.backgroundColorThemed = Palette.shared.clear
    }

    /// Dates & Guests
    private lazy var horizontalStackView = with(UIStackView()) {
        $0.axis = .horizontal
        $0.distribution = .fillProportionally
    }

    private lazy var placeView = HotelFormRowView()
    private lazy var datesView = HotelFormRowView()
    private lazy var guestsView = HotelFormRowView()

    private let appearance: Appearance

    var onPlaceTap: (() -> Void)?
    var onDatesTap: (() -> Void)?
    var onGuestsTap: (() -> Void)?

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

        self.setupTapActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupPlace(_ place: HotelFormRowViewModel) {
        self.placeView.setup(with: place)
    }

    func setupDates(_ dates: HotelFormRowViewModel) {
        self.datesView.setup(with: dates)
    }

    func setupGuests(_ guests: HotelFormRowViewModel) {
        self.guestsView.setup(with: guests)
    }

    // MARK: - Helpers

    private func setupTapActions() {
        self.placeView.addTapHandler { [weak self] in
            self?.onPlaceTap?()
        }
        self.datesView.addTapHandler { [weak self] in
            self?.onDatesTap?()
        }
        self.guestsView.addTapHandler { [weak self] in
            self?.onGuestsTap?()
        }
    }

    private func placeVerticalSeparator(on view: UIView) {
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

extension HotelFormView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.layer.cornerRadius = self.appearance.cornerRadius

        self.placeVerticalSeparator(on: self.guestsView)
    }

    func addSubviews() {
        [
            self.datesView,
            self.guestsView
        ].forEach(self.horizontalStackView.addArrangedSubview)

        [
            self.placeView,
            self.horizontalStackView
        ].forEach(self.stackView.addArrangedSubview)

        self.addSubview(self.stackView)
    }

    func makeConstraints() {
        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.datesView.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.7)
        }
    }
}
