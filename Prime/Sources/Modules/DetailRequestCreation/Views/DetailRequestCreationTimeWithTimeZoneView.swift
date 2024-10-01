import UIKit

struct TimeZoneInfo {
    let identifier: String
    let abbreviation: String
    let secondsFromGMT: Int
    let timeZone: TimeZone

    var description: String {
        let hoursGMTDiff = secondsFromGMT / 60 / 60
        let hoursGMTDiffString = hoursGMTDiff < 0 ? "\(hoursGMTDiff)" : "+\(hoursGMTDiff)"

        let minutesGMTDiff = abs(secondsFromGMT) / 60 % 60
        let minutesGMTDiffString = minutesGMTDiff < 10 ? "0\(minutesGMTDiff)" : "\(minutesGMTDiff)"
        return "(GMT\(hoursGMTDiffString):\(minutesGMTDiffString)) \(identifier) \(abbreviation)"
    }

    init?(identifier: String, abbreviation: String) {
        self.identifier = identifier
        self.abbreviation = abbreviation
        if let timeZone = TimeZone(abbreviation: abbreviation) {
            self.timeZone = timeZone
            self.secondsFromGMT = timeZone.secondsFromGMT()
        } else {
            return nil
        }
    }
}

extension DetailRequestCreationTimeWithTimeZoneView {
    struct Appearance: Codable {
        var skyFont = Palette.shared.primeFont.with(size: 12)
        var skyColor = Palette.shared.gray1

        var textFieldFont = Palette.shared.primeFont.with(size: 15)
        var textFieldColor = Palette.shared.mainBlack

        var backgroundColor = Palette.shared.gray5

        var separatorColor = Palette.shared.gray3

        var datePickerBackgroundColor = Palette.shared.gray5

        var toolbarTintColor = Palette.shared.brandPrimary
        var toolbarItemTintColor = Palette.shared.gray5
        var toolbarItemFont = Palette.shared.primeFont.with(size: 15)
    }
}

class DetailRequestCreationTimeWithTimeZoneView: UIView, TaskFieldValueInputProtocol {
    var onDateSelected: ((String) -> Void)?
    var onTimeZoneSelected: ((TimeZone) -> Void)?

    private var didInitTimeZone = false

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = self.appearance.backgroundColor
        return view
    }()

    private lazy var dateTextField: DetailRequestCreationTextField = {
        let view = DetailRequestCreationTextField(type: .date)
        view.onDateSelected = { [weak self] dateString in
            guard let strongSelf = self else {
                return
            }
            strongSelf.onDateSelected?(dateString)
            if !strongSelf.didInitTimeZone {
                strongSelf.timeZoneTextField.setCurrentTimeZone()
                strongSelf.didInitTimeZone = true
            }
        }
        return view
    }()

    private lazy var timeZoneTextField: DetailRequestCreationTextField = {
        let view = DetailRequestCreationTextField(type: .timeZone)
        view.onTimeZoneSelected = { [weak self] timeZone in
            self?.onTimeZoneSelected?(timeZone)
        }
        return view
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private let appearance: Appearance

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: TaskCreationFieldViewModel) {
		let time = viewModel.input.dtValue
		let zone = viewModel.input.newValue

		viewModel.input.newValue = time ?? ""
        self.dateTextField.setup(with: viewModel)
		let onValidateDate = viewModel.onValidate

		viewModel.input.newValue = zone
        self.timeZoneTextField.setup(with: viewModel)
		let onValidateTimeZone = viewModel.onValidate

		viewModel.onValidate = { (isValid, message) in
			onValidateDate?(isValid, message)
			onValidateTimeZone?(isValid, message)
		}
    }
}

extension DetailRequestCreationTimeWithTimeZoneView: Designable {
    func addSubviews() {
        self.addSubview(self.backgroundView)
        [self.dateTextField, self.timeZoneTextField, self.separatorView].forEach(self.backgroundView.addSubview)
    }

    func makeConstraints() {
        self.backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.dateTextField.snp.makeConstraints { make in
            make.leading.bottom.top.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
        }

        self.timeZoneTextField.snp.makeConstraints { make in
            make.bottom.top.trailing.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
            make.leading.equalTo(self.dateTextField.snp.trailing)
        }
    }
}

