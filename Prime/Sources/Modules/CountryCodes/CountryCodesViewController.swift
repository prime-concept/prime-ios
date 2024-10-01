import PhoneNumberKit
import UIKit

extension CountryCodesViewController {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var collectionBackgroundColor = Palette.shared.clear
        var collectionItemSize = CGSize(width: UIScreen.main.bounds.width, height: 55)
        var searchTextFieldCornerRadius: CGFloat = 10
        var grabberViewBackgroundColor = Palette.shared.gray3
        var grabberCornerRadius: CGFloat = 2
        var applyBackgroundColor = Palette.shared.brandPrimary
        var applyTextColor = Palette.shared.gray5
        var clearTextColor = Palette.shared.gray0
        var clearBackgroundColor = Palette.shared.clear
        var clearBorderWidth: CGFloat = 0.5
        var clearBorderColor = Palette.shared.gray3
        var buttonCornerRadius: CGFloat = 8
    }
}

final class CountryCodesViewController: UIViewController {
    private lazy var grabberView: UIView = {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 36, height: 3))
        }
        view.layer.cornerRadius = self.appearance.grabberCornerRadius
        view.backgroundColorThemed = self.appearance.grabberViewBackgroundColor
        return view
    }()

    private lazy var searchTextField: SearchTextField = {
        let searchTextField = SearchTextField(
            placeholder: Localization.localize("detailRequestCreation.airports.search")
        )
        searchTextField.layer.cornerRadius = self.appearance.searchTextFieldCornerRadius
        searchTextField.clipsToBounds = true
        searchTextField.delegate = self
        searchTextField.setEventHandler(for: .editingChanged) { [weak self] in
            guard let self = self else {
                return
            }
            self.search(with: searchTextField.text ?? "")
        }
        return searchTextField
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.appearance.collectionItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellClass: CountryCodeCollectionViewCell.self)
        return collectionView
    }()

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.cancelButton, self.applyButton])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        return stackView
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        let title = Localization.localize("detailRequestCreation.cancel").attributed()
            .foregroundColor(self.appearance.clearTextColor)
            .primeFont(ofSize: 16, lineHeight: 20)
            .string()
        button.setAttributedTitle(title, for: .normal)
        button.backgroundColorThemed = self.appearance.clearBackgroundColor
        button.layer.borderWidth = self.appearance.clearBorderWidth
        button.layer.borderColorThemed = self.appearance.clearBorderColor
        button.layer.cornerRadius = self.appearance.buttonCornerRadius
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.dismiss(animated: true)
        }
        return button
    }()

    private lazy var applyButton: UIButton = {
        let button = UIButton(type: .system)
        let title = Localization.localize("selection.apply").attributed()
            .foregroundColor(self.appearance.applyTextColor)
            .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
            .string()
        button.setAttributedTitle(title, for: .normal)
        button.backgroundColorThemed = self.appearance.applyBackgroundColor
        button.layer.cornerRadius = self.appearance.buttonCornerRadius
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            guard let self = self else {
                return
            }
            self.dismiss(animated: true) {
                self.onSelect(self.selectedCountryCode)
            }
        }
        return button
    }()

    private var data: [CountryCode] {
        var data = self.phoneNumberKit.allCountries().compactMap { country -> CountryCode? in
            guard let code = self.phoneNumberKit.countryCode(for: country),
                  let name = (Locale.current as NSLocale).localizedString(forCountryCode: country) else {
                return nil
            }
            return CountryCode(code: String(code), country: name)
        }.sorted(by: { $0.country.caseInsensitiveCompare($1.country) == .orderedAscending })
        if let index = data.firstIndex(where: {
            $0.code == self.selectedCountryCode.code
        }) {
            data[index].isSelected = true
        }
        return data
    }

    private lazy var phoneNumberKit = PhoneNumberKit()
    private var selectedCountryCode: CountryCode
    private var filteredData: [CountryCode] = []
    private let appearance: Appearance
    private let onSelect: (CountryCode) -> Void

    var scrollView: UIScrollView? {
        self.collectionView
    }

    init(
        countryCode: CountryCode,
        appearance: Appearance = Theme.shared.appearance(),
        onSelect: @escaping (CountryCode) -> Void
    ) {
        self.selectedCountryCode = countryCode
        self.appearance = appearance
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        self.filteredData = self.data
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }

    // MARK: - Private

    private func search(with query: String) {
        let filteredData = self.data.filter { countryCode in
            let doesContainCountry = countryCode.country.lowercased().contains(query.lowercased())
            let doesContaintCode = countryCode.code.lowercased().contains(query.lowercased())
            return doesContainCountry || doesContaintCode
        }
        self.filteredData = query.isEmpty ? self.data : filteredData
        self.collectionView.reloadData()
    }

    private func handleSelection(at index: Int) {
        if let previouslySelectedIndex = self.filteredData.firstIndex(where: { $0.isSelected }) {
            self.filteredData[previouslySelectedIndex].isSelected.toggle()
            self.filteredData[index].isSelected.toggle()
        }
    }

    private func setupView() {
        self.view.backgroundColorThemed = self.appearance.backgroundColor
        [
            self.grabberView,
            self.searchTextField,
            self.collectionView,
            self.buttonsStackView
        ].forEach(view.addSubview)

        self.grabberView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
            make.centerX.equalToSuperview()
        }

        self.searchTextField.snp.makeConstraints { make in
            make.top.equalTo(self.grabberView.snp.bottom).offset(17)
            make.height.equalTo(36)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.searchTextField.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
        }

        self.cancelButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.applyButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        self.buttonsStackView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-15)
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.equalTo(self.collectionView.snp.bottom).offset(10)
        }
    }
}

extension CountryCodesViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        self.filteredData.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell: CountryCodeCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.setup(with: self.filteredData[indexPath.row])
        return cell
    }
}

extension CountryCodesViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        self.searchTextField.resignFirstResponder()
        let item = self.filteredData[indexPath.row]
        if item.isSelected {
            return
        }
        self.selectedCountryCode = item
        self.handleSelection(at: indexPath.row)
        self.collectionView.reloadData()
    }
}

extension CountryCodesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
