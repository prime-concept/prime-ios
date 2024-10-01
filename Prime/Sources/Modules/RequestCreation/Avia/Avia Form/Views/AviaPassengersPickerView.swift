import UIKit

struct AviaPassengersPickerModel {
    let title: String
    let values: [PassengerClass]
    let selectedIndex: Int?
    let pickerInvoker: () -> Void
}

class AviaPassengersPickerView: UIView {
    private lazy var valueLabel = UILabel()
    private lazy var passengerImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "avia_passenger"))
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

    func setup(with model: AviaPassengerModel) {
        let total = String(model.total)
        let value = total + ", " + (model.isShowOnlyPassengers
                                    ? model.passengerTitle.lowercased()
                                    : model.class.lowercased())
        
        self.valueLabel.attributedTextThemed = Self.makeValue(value)
    }

    private static func makeValue(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 13, lineHeight: 16)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }
}

extension AviaPassengersPickerView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.valueLabel,
            self.passengerImageView,
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
        self.passengerImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.leading.equalToSuperview()
        }
        self.valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.passengerImageView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        self.arrowImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.bottom.top.trailing.equalToSuperview()
            make.leading.equalTo(self.valueLabel.snp.trailing)
        }
    }
}

enum PassengerClass: CaseIterable {
    case economy
    case business

    var localize: String {
        switch self {
        case .economy:
            return "avia.class.economy".localized
        case .business:
            return "avia.class.business".localized
        }
    }
}

enum PassengersAge {
    case adults(Int)
    case children(Int)
    case infants(Int)

    var localize: String {
        switch self {
        case .adults:
            return "avia.age.adults".localized
        case .children:
            return "avia.age.children".localized
        case .infants:
            return "avia.age.infants".localized
        }
    }
}
