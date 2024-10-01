import PrimeUtilities
import UIKit

extension HotelsListView {
    struct Appearance: Codable {
        var collectionBackground = Palette.shared.gray5
        var collectionItemSize = CGSize(width: UIScreen.main.bounds.width, height: 55)
        var collectionHeaderReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 20)
        var collectionSectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        var searchTextFieldCornerRadius: CGFloat = 18
        var segmentTitleFont = Palette.shared.primeFont.with(size: 14)
        var segmentselectedTitleColor = Palette.shared.gray0
        var segmentDeselectedTitleColor = Palette.shared.gray1
    }
}

enum CategoryFilter: Int {
    case top
    case hotels
    case cities
    
    var title: String {
        switch self {
        case .top:
            return "hotel.top.list.title".localized
        case .hotels:
            return "hotel.list.title".localized
        case .cities:
            return "hotel.cities.list.title".localized
        }
    }
    
    static var itemList: [String] {
        return [top.title, hotels.title, cities.title]
    }
}

final class HotelsListView: UIView {
    fileprivate enum Constants {
        static let hotelsSectionIndex = 0
        static let citiesSectionIndex = 1
    }
    
    private lazy var searchTextField: SearchTextField = {
        let searchTextField = SearchTextField(
            placeholder: "common.search".localized
        )
        searchTextField.autocorrectionType = .no
        searchTextField.layer.cornerRadius = self.appearance.searchTextFieldCornerRadius
        searchTextField.clipsToBounds = true
        searchTextField.delegate = self
        searchTextField.setEventHandler(for: .editingChanged) { [weak self] in
            self.some { (self) in
                let query = self.searchTextField.text^
                self.onSearchQueryChanged?(self.searchTextField.text ?? "")
            }
        }
        return searchTextField
    }()
    
    private lazy var categoriesSegmentControl: CustomSegmentView = {
        let segmentControl = CustomSegmentView()
        segmentControl.segmentTitles = CategoryFilter.itemList
        segmentControl.titleFont = appearance.segmentTitleFont.rawValue
        segmentControl.selectedTitleColor = appearance.segmentselectedTitleColor.rawValue
        segmentControl.deselectedTitleColor = appearance.segmentDeselectedTitleColor.rawValue
        
        segmentControl.onSegmentChanged = { [weak self] index in
            self?.filterType = CategoryFilter(rawValue: index) ?? .top
            self?.collectionView.reloadData()
            self?.collectionView.setContentOffset(.zero, animated: true)
            self?.onFilterCategorySelected?(CategoryFilter(rawValue: index) ?? .top)
        }
        return segmentControl
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.itemSize = self.appearance.collectionItemSize
        layout.sectionHeadersPinToVisibleBounds = true
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackground
        collectionView.keyboardDismissMode = .onDrag
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(cellClass: HotelCollectionViewCell.self)
        collectionView.register(cellClass: HotelCityCollectionViewCell.self)
        collectionView.register(
            viewClass: HotelsListHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
        return collectionView
    }()
    
    private lazy var noQueryResultsView = UIView()
    private let appearance: Appearance
    private var data: HotelsListViewModel?
    private var filterType: CategoryFilter = .top
    
    var onHotelSelected: ((Int) -> Void)?
    var onCitySelected: ((Int) -> Void)?
    var onSearchQueryChanged: ((String) -> Void)?
    var onFilterCategorySelected: ((CategoryFilter) -> Void)?
    
    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)
        
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
       
        self.searchTextField.becomeFirstResponder()
    }
    
    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with viewModel: HotelsListViewModel) {
        
        if viewModel.hotels.isEmpty && viewModel.cities.isEmpty {
            self.noQueryResultsView.isHidden = !viewModel.isSearchActive
            self.collectionView.isHidden = true
            return
        }
        
        self.noQueryResultsView.isHidden = true
        self.collectionView.isHidden = false
        self.data = viewModel
        self.collectionView.reloadData()
    }
    
    private func setNoQueryResultsView() {
        let titleLabel = UILabel()
        let subtitleLabel = UILabel()
        
        titleLabel.attributedTextThemed = "hotel.list.no.results.title".localized.attributed()
            .foregroundColor(Palette.shared.gray0)
            .font(Palette.shared.primeFont.with(size: 16, weight: .medium))
            .lineHeight(20)
            .alignment(.center)
            .string()
        
        subtitleLabel.attributedTextThemed = "hotel.list.no.results.subtitle".localized.attributed()
            .foregroundColor(Palette.shared.gray0)
            .font(Palette.shared.primeFont.with(size: 13))
            .lineHeight(16)
            .alignment(.center)
            .string()
        subtitleLabel.numberOfLines = 0
        
        [
            titleLabel,
            subtitleLabel
        ].forEach(self.noQueryResultsView.addSubview)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(15)
        }
        
        self.noQueryResultsView.isHidden = true
    }
}

extension HotelsListView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.collectionBackground
        self.setNoQueryResultsView()
    }
    
    func addSubviews() {
        [
            self.collectionView,
            self.searchTextField,
            self.categoriesSegmentControl,
            self.noQueryResultsView
        ].forEach(self.addSubview)
    }
    
    func makeConstraints() {
        self.searchTextField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(36)
        }
        
        self.categoriesSegmentControl.snp.makeConstraints { make in
            make.top.equalTo(self.searchTextField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.trailing.trailing.equalToSuperview()
            make.height.equalTo(45)
        }
        
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.categoriesSegmentControl.snp.bottom).offset(24)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        self.noQueryResultsView.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.76)
            make.height.equalTo(57)
            make.top.equalToSuperview().offset(UIScreen.main.bounds.height * 0.25)
            make.centerX.equalToSuperview()
        }
    }
}

extension HotelsListView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.filterType == .top ? 2 : 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
    
        switch self.filterType {
        case .top:
            switch section {
            case Constants.hotelsSectionIndex:
                return min((self.data?.hotels.count)^, 5)
            case Constants.citiesSectionIndex:
                return min((self.data?.cities.count)^, 5)
            default:
                return 0
            }
        case .hotels:
            return (self.data?.hotels.count)^
        case .cities:
            return (self.data?.cities.count)^
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        switch self.filterType {
        case .top:
            switch indexPath.section {
            case Constants.hotelsSectionIndex:
                let cell: HotelCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
                
                let topHotelsCount = min((self.data?.hotels.count)^, 5)
                let topHotels = self.data?.hotels.prefix(topHotelsCount)
                
                if let hotel = topHotels?[safe:indexPath.item] {
                    cell.setup(with: hotel)
                }
                return cell
            case Constants.citiesSectionIndex:
                let cell: HotelCityCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
                
                let topCitiesCount = min((self.data?.cities.count)^, 5)
                let topCities = self.data?.cities.prefix(topCitiesCount)
                
                if let city = topCities?[safe:indexPath.item] {
                    cell.setup(with: city)
                }
                return cell
            default:
                return UICollectionViewCell()
            }
        case .hotels:
            let cell: HotelCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            if let hotel = self.data?.hotels[indexPath.item] {
                cell.setup(with: hotel)
            }
            return cell
        case .cities:
            let cell: HotelCityCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            if let city = self.data?.cities[indexPath.item] {
                cell.setup(with: city)
            }
            return cell
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader
        else {
            return UICollectionReusableView()
        }
        
        let view: HotelsListHeaderView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            for: indexPath
        )
        var title = ""
        if case .top = self.filterType {
            title = indexPath.section == Constants.hotelsSectionIndex
            ? self.data?.hotelsTitle ?? ""
            : self.data?.citiesTitle ?? ""
        }
        
        view.set(title: title)
        return view
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        
        if case .top = filterType {
            if let hotels = self.data?.hotels, !hotels.isEmpty && section == Constants.hotelsSectionIndex {
                return self.appearance.collectionSectionInset
            }
            if let cities = self.data?.cities, !cities.isEmpty && section == Constants.citiesSectionIndex {
                return self.appearance.collectionSectionInset
            }
        }
        return .zero
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        
        if case .top = self.filterType {
            if let hotels = self.data?.hotels, !hotels.isEmpty && section == Constants.hotelsSectionIndex {
                return self.appearance.collectionHeaderReferenceSize
            }
            if let cities = self.data?.cities, !cities.isEmpty && section == Constants.citiesSectionIndex {
                return self.appearance.collectionHeaderReferenceSize
            }
        }
        return .zero
    }
}

extension HotelsListView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        switch self.filterType {
        case .top:
            switch indexPath.section {
            case Constants.hotelsSectionIndex:
                guard let selectedHotel = self.data?.hotels[indexPath.item]
                else { return }
                self.onHotelSelected?(selectedHotel.id)
            case Constants.citiesSectionIndex:
                guard let selectedCity = self.data?.cities[indexPath.item]
                else { return }
                self.onCitySelected?(selectedCity.id)
            default:
                return
            }
        case .hotels:
            guard let selectedHotel = self.data?.hotels[indexPath.item]
            else { return }
            self.onHotelSelected?(selectedHotel.id)
        case .cities:
            guard let selectedCity = self.data?.cities[indexPath.item]
            else { return }
            self.onCitySelected?(selectedCity.id)
        }
    }
}

extension HotelsListView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }
}

