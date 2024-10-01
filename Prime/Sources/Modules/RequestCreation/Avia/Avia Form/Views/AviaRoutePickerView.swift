import UIKit

class AviaRoutePickerView: UIView {
    private lazy var valueLabel = UILabel()
    private lazy var routeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
		view.tintColorThemed = Palette.shared.brandSecondary
        return view
    }()

    private lazy var arrowImage: UIImageView = {
        let view = UIImageView(image: UIImage(named: "avia_arrow_down"))
        view.contentMode = .scaleAspectFit
		view.tintColorThemed = Palette.shared.brandSecondary
        return view
    }()

    private lazy var containerView = UIView()

    override init(frame: CGRect = .zero) {
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with route: AviaRoute) {
        self.routeImageView.image = route.image
        self.valueLabel.attributedTextThemed = Self.makeValue(route.title)
    }
}

extension AviaRoutePickerView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.valueLabel,
            self.routeImageView,
            self.arrowImage
        ].forEach(self.containerView.addSubview)
        self.valueLabel.numberOfLines = 1
        self.valueLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.bottom.equalToSuperview().inset(5)
            make.trailing.equalToSuperview().inset(10)
        }

        self.routeImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.leading.equalToSuperview().offset(5)
        }

        self.valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.routeImageView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }

        self.arrowImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.bottom.top.trailing.equalToSuperview()
            make.leading.equalTo(self.valueLabel.snp.trailing)
        }
    }
    
    private static func makeValue(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 13, lineHeight: 16)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }
}

enum AviaRoute: Int, CaseIterable {
    case oneWay = 1
    case roundTrip = 0
    case multiCity = 2

    var title: String {
        switch self {
        case .oneWay:
            return "avia.route.one".localized
        case .roundTrip:
            return "avia.route.round".localized
        case .multiCity:
            return "avia.route.multi".localized
        }
    }

    var image: UIImage? {
        switch self {
        case .oneWay:
            return UIImage(named: "one_way")
        case .roundTrip:
            return UIImage(named: "round_trip")
        case .multiCity:
            return UIImage(named: "multi_city")
        }
    }

    static var `default`: AviaRoute {
        .roundTrip
    }
}
