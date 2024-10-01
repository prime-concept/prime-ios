import UIKit

extension TimeZonePickerView {
    struct Appearance: Codable {
        var height: CGFloat = 216
    }
}

class TimeZonePickerView: UIView {
    private(set) var selectedTimeZone: TimeZone

    private lazy var pickerView: UIPickerView = {
        let view = UIPickerView()
        view.delegate = self
        view.dataSource = self
        view.showsSelectionIndicator = true
        return view
    }()

    private lazy var timeZones: [TimeZoneInfo] = {
        TimeZone.abbreviationDictionary
            .compactMap { TimeZoneInfo(identifier: $1, abbreviation: $0) }
            .sorted(by: { $0.secondsFromGMT < $1.secondsFromGMT })
    }()

    private let appearance: Appearance

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance(),
        defaultTimeZone: TimeZone
    ) {
        self.appearance = appearance
        self.selectedTimeZone = defaultTimeZone

        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
        self.pickerView.reloadAllComponents()
        self.pickerView.selectRow(
            self.timeZones.firstIndex(where: { $0.timeZone == defaultTimeZone }) ?? 0,
            inComponent: 0,
            animated: false
        )
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimeZonePickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        self.timeZones.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        self.timeZones[row].description
    }
}

extension TimeZonePickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedTimeZone = self.timeZones[row].timeZone
    }
}


extension TimeZonePickerView: Designable {
    func addSubviews() {
        self.addSubview(self.pickerView)
    }

    func makeConstraints() {
        self.snp.makeConstraints { make in
            make.height.equalTo(appearance.height)
        }

        self.pickerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
