import UIKit
import GRDB

extension AirportListView {
    struct Appearance: Codable {
        var collectionBackground = Palette.shared.gray5
        var collectionItemSize = CGSize(width: UIScreen.main.bounds.width, height: 55)
        var collectionItemReducedSize = CGSize(width: UIScreen.main.bounds.width - 50, height: 55)
        
        var searchTextFieldCornerRadius: CGFloat = 18
    }
    
    var scrollView: UIScrollView {
        self.collectionView
    }
}

final class AirportListView: ChatKeyboardDismissingView {
    private lazy var searchTextField: SearchTextField = {
        let searchTextField = SearchTextField(
            placeholder: Localization.localize("detailRequestCreation.airports.search")
        )
        searchTextField.autocorrectionType = .no
        searchTextField.layer.cornerRadius = self.appearance.searchTextFieldCornerRadius
        searchTextField.clipsToBounds = true
        searchTextField.delegate = self
        
        searchTextField.setEventHandler(for: .editingChanged) { [weak self] in
            guard let self else { return }
            self.onSearchQueryChanged?(self.searchTextField.text ?? "")
        }
        
        return searchTextField
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 40)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = self.appearance.collectionBackground
        collectionView.keyboardDismissMode = .onDrag
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(cellClass: AirportCollectionViewCell.self)
        collectionView.register(
            viewClass: AirportListHeaderReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
        collectionView.register(
            viewClass: AirportListLocationHeaderReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )
        
        return collectionView
    }()
    
    private let appearance: Appearance
    private var viewModel: AirportListsViewModel?
    private var sourceViewModel: AirportListsViewModel?
    
    var onAirportSelected: ((AirportSelection) -> Void)?
    var onSearchQueryChanged: ((String) -> Void)?
    
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
    
    func setup(with viewModel: AirportListsViewModel) {
        self.viewModel = self.handleAirportListFrom(viewModel: viewModel)
        self.sourceViewModel = viewModel
        self.collectionView.reloadData()
    }

    /// Removing all airports where "isHub == true"
    /// - Parameter viewModel: model helping to fill airport list tableView
    /// - Returns: same viewModel without airports where "isHub == true"
    private func handleAirportListFrom(viewModel: AirportListsViewModel) -> AirportListsViewModel {
        var handledModel: AirportListsViewModel = viewModel
        
        viewModel.airportLists.forEach { airportViewModel in
			let airports = airportViewModel.airports.skip(\.isHub)
			let index = handledModel.airportLists.firstIndex{ $0 == airportViewModel }

            if let index {
                handledModel.airportLists[index].airports = airports
            }
        }
        return handledModel
    }
}

extension AirportListView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.collectionBackground
    }
    
    func addSubviews() {
        [self.collectionView, self.searchTextField].forEach(self.addSubview)
    }
    
    func makeConstraints() {
        self.searchTextField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.collectionView.snp.top)
            make.height.equalTo(36)
        }
        
        self.collectionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension AirportListView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let viewModel = viewModel else {
            return 0
        }
        return viewModel.airportLists.count
    }
    
	func collectionView(
		_ collectionView: UICollectionView,
		numberOfItemsInSection section: Int
	) -> Int {
		guard let viewModel = viewModel else {
			return 0
		}

		let list = viewModel.airportLists[section]

		if list.isExpanded {
			return list.airports.count
		}

		return 0
	}
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let viewModel = viewModel else {
            return UICollectionViewCell()
        }
        let cell: AirportCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        let airportsSection = viewModel.airportLists[indexPath.section].airports
        cell.setup(with: airportsSection[indexPath.item])
        
        return cell
    }
}

extension AirportListView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let viewModel = viewModel else {
            return
        }
        let selectedAirport = viewModel.airportLists[indexPath.section].airports[indexPath.item]
		onAirportSelected?(.airport(id: selectedAirport.id))
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard let viewModel = self.viewModel else {
            return .zero
        }
        if section == 0 && viewModel.isFirstSectionNear {
            return CGSize(width: collectionView.frame.width, height: 40)
        } else {
            return CGSize(width: collectionView.frame.width, height: 55)
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
		guard kind == UICollectionView.elementKindSectionHeader else {
			return UICollectionReusableView()
		}

		guard let viewModel = self.viewModel else {
			return UICollectionReusableView()
		}

		if indexPath.section == 0 && viewModel.isFirstSectionNear {
			let view: AirportListHeaderReusableView = collectionView.dequeueReusableSupplementaryView(
				ofKind: UICollectionView.elementKindSectionHeader,
				for: indexPath
			)
			view.title = viewModel.airportLists[indexPath.section].header.title
			return view
		}

		let headerView = collectionView.dequeueReusableSupplementaryView(
			ofKind: UICollectionView.elementKindSectionHeader,
			for: indexPath
		) as AirportListLocationHeaderReusableView

		headerView.onArrowButtonTap = {
			self.viewModel?.airportLists[indexPath.section].isExpanded.toggle()
			UIView.transition(
				with: self.collectionView,
				duration: 0.2,
				options: .curveLinear) {
					collectionView.reloadSections([indexPath.section])
				}
		}

        headerView.addTapHandler { [weak self] in
            
            guard let self, let sourceViewModel = self.sourceViewModel, viewModel.mayTapOnCityHub else { return }
            
            let viewModel = sourceViewModel.airportLists[indexPath.section]
            let selectedAirports = viewModel.airports
            
            if selectedAirports.count == 1, let airport = selectedAirports.first {
                self.onAirportSelected?(.airport(id: airport.id))
                return
            }
            
            if let hubAirPort = selectedAirports.first(where: { $0.isHub }) {
                self.onAirportSelected?(.airport(id: hubAirPort.id))
                return
            }
            
            let cityName = [viewModel.header.title, viewModel.header.subtitle].joined(", ")
            self.onAirportSelected?(.city(name: cityName))
        }

		let section = viewModel.airportLists[indexPath.section]
		let headerViewModel = AirportListHeaderViewModel(
			title: section.header.title,
			subtitle: section.header.subtitle,
			isExpanded: section.isExpanded
		)
		headerView.setup(with: headerViewModel)

		return headerView
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let viewModel = self.viewModel else {
            return .zero
        }
        
        if indexPath.section == 0 && viewModel.isFirstSectionNear {
            return self.appearance.collectionItemSize
        }
        
        return self.appearance.collectionItemReducedSize
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard let viewModel = self.viewModel else {
            return .zero
        }
        
        if section == 0 && viewModel.isFirstSectionNear {
            return .zero
        }
        
        return .init(top: 0, left: 35, bottom: 0, right: 0)
    }
}

extension AirportListView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }
}
