import Foundation
import UIKit

extension PersonsViewController {
    struct Appearance: Codable {
        var mainViewBackgroundColor = Palette.shared.gray5
        var buttonBarBackgroundColor = Palette.shared.gray5
        var buttonBarItemBackgroundColor = Palette.shared.gray5
        var backgroundColor = Palette.shared.clear
        var selectedBarBackgroundColor = Palette.shared.brown
        var barBackgroundColor = Palette.shared.gray3

        var oldCellLabelTextColor = Palette.shared.gray1
        var newCellLabelTextColor = Palette.shared.gray0

        var addButtonTitleColor = Palette.shared.gray0
        var addButtonBackgroundColor = Palette.shared.gray5

        var selectedBarHeight: CGFloat = 0.5
        var familyItemSize = CGSize(width: 100, height: 130)

        var navigationTintColor = Palette.shared.gray5
        var navigationBarGradientColors = [
            Palette.shared.brandPrimary,
            Palette.shared.brandPrimary
        ]
    }
}

protocol PersonsViewControllerProtocol: AnyObject {
    func showActivity()
    func hideActivity()
    func presentDocuments(index: Int, shouldOpenInCreationMode: Bool)
    func presentContacts(index: Int, shouldOpenInCreationMode: Bool)
    func update(with familyMembers: [PersonsViewModels])
    func presentForm(controller: UIViewController)
}

final class PersonsViewController: UIViewController {
    private let indexToMove: Int?
    private let appearance: Appearance
    private let presenter: PersonsPresenterProtocol
    private var navigationBarShadowImage: UIImage?
    private var selectedIndex: Int = 0
    private var cells: [PersonsViewModels] = []
    private var viewModel: ProfilePersonalInfoViewModel?
    private let shouldOpenInCreationMode: Bool
    private lazy var docView = PersonsInfoView()
    private lazy var contactsView = PersonsInfoView()
    private lazy var detailInfoView = PersonsDetailInfoView()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15);
        collectionView.backgroundColorThemed = Palette.shared.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsMultipleSelection = false
        collectionView.register(
            PersonsItemCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonsItemCollectionViewCell.defaultReuseIdentifier
        )
        collectionView.register(
            PersonsItemAddCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonsItemAddCollectionViewCell.defaultReuseIdentifier
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    private lazy var editButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("persons.edit")
            .attributed()
            .primeFont(ofSize: 16, weight: .regular, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.addButtonTitleColor)
            .string()

        label.backgroundColorThemed = self.appearance.addButtonBackgroundColor
        label.clipsToBounds = true
        label.layer.cornerRadius = 8
        label.layer.borderColorThemed = Palette.shared.gray3
        label.layer.borderWidth = 1 / UIScreen.main.scale
        return label
    }()

    init(
        indexToMove: Int?,
        presenter: PersonsPresenterProtocol,
        appearance: Appearance = Theme.shared.appearance(),
        shouldOpenInCreationMode: Bool = false
    ) {
        self.appearance = appearance
        self.indexToMove = indexToMove
        self.presenter = presenter
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override var preferredStatusBarStyle: UIStatusBarStyle {
		.lightContent
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.makeConstraints()
        self.editButton.addTapHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.presenter.openForm(contactIndex: strongSelf.selectedIndex)
        }
        self.presenter.loadFamilyMembers()
        self.selectedIndex = self.indexToMove ?? 0
        if self.shouldOpenInCreationMode {
            self.presenter.presentForm(for: .newContact)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.navigationBar.shadowImage = self.navigationBarShadowImage
    }

    private func setupUI() {
        self.navigationItem.titleView = { () -> UIView in
            let label = UILabel()
            label.attributedTextThemed = Localization.localize("persons.title").attributed()
                .foregroundColor(self.appearance.navigationTintColor)
                .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
                .string()
            return label
        }()
        self.hideDetailInfo()
        self.collectionView.isHidden = true
        self.view.backgroundColorThemed = self.appearance.mainViewBackgroundColor
        self.navigationController?.navigationBar.tintColorThemed = self.appearance.navigationTintColor

        self.navigationBarShadowImage = self.navigationController?.navigationBar.shadowImage
        self.navigationController?.navigationBar.shadowImage = UIImage()

        if let navigationController = self.navigationController {
            navigationController.navigationBar.setGradientBackground(
                to: navigationController,
                colors: self.appearance.navigationBarGradientColors
            )
        }
    }
    
    private func hideDetailInfo() {
        self.detailInfoView.isHidden = true
        self.editButton.isHidden = true
        self.docView.isHidden = true
        self.contactsView.isHidden = true
    }

    private func selectItem(at index: Int) {
        self.selectedIndex = index
        self.detailInfoView.setupInfo(with: self.cells[index].personInfo)
        self.docView.setup(with: self.cells[index].docs)
        self.contactsView.setup(with: self.cells[index].contacts)
        self.editButton.isHidden = false
    }

    private func makeConstraints() {
        self.view.addSubview(self.stackView)
        [
            self.detailInfoView,
            self.collectionView,
            self.docView,
            self.contactsView,
            self.editButton
        ].forEach(self.stackView.addSubview)
        
        self.editButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }
        self.stackView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.safeAreaLayoutGuide)
        }
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(self.appearance.familyItemSize.height)
        }
        self.detailInfoView.snp.makeConstraints { make in
            make.top.equalTo(self.collectionView.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview()
        }
        self.docView.snp.makeConstraints { make in
            make.top.equalTo(self.detailInfoView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
        }
        self.contactsView.snp.makeConstraints { make in
            make.top.equalTo(self.docView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
        }
    }
}

extension PersonsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == self.cells.count {
            let cell: PersonsItemAddCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonsItemCollectionViewCell.defaultReuseIdentifier, for: indexPath) as? PersonsItemCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: cells[indexPath.row].personInfo)
        if selectedIndex == indexPath.row {
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            self.selectItem(at: indexPath.row)
            cell.isSelected = true
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cells.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.cellForItem(at: indexPath) is PersonsItemAddCollectionViewCell {
            self.presenter.presentForm(for: .newContact)
        }
        guard let cell = collectionView.cellForItem(at: indexPath)
          as? PersonsItemCollectionViewCell else { return }
        cell.isSelected = true
        self.selectItem(at: indexPath.row)
    }
}

extension PersonsViewController: PersonsViewControllerProtocol {
    func presentDocuments(index: Int, shouldOpenInCreationMode: Bool) {
        let controller = PersonDocumentsAssembly(
            indexToMove: index,
            shouldOpenInCreationMode: shouldOpenInCreationMode,
            personId: self.cells[self.selectedIndex].personInfo.personId
        ).make()
        let router = PushRouter(source: self, destination: controller)
        router.route()
    }
    
    func presentContacts(index: Int, shouldOpenInCreationMode: Bool) {
        let controller = PersonContactsAssembly(
            indexToMove: index,
            shouldOpenInCreationMode: shouldOpenInCreationMode,
            personId: self.cells[self.selectedIndex].personInfo.personId
        ).make()
        let router = PushRouter(source: self, destination: controller)
        router.route()
    }
    
    func presentForm(controller: UIViewController) {
        DispatchQueue.main.async {
            self.collectionView.selectItem(at: IndexPath(row: self.selectedIndex, section: 0), animated: true, scrollPosition: .right)
        }
        ModalRouter(
            source: self,
            destination: controller,
            modalPresentationStyle: .pageSheet
        ).route()
    }
    
    func update(with familyMembers: [PersonsViewModels]) {
        self.hideActivity()
        if self.cells.count < familyMembers.count && !self.cells.isEmpty {
            self.selectedIndex = familyMembers.count - 1
        } else if (self.cells.count > familyMembers.count) {
            self.selectedIndex = 0
        }
        self.cells = familyMembers
        collectionView.reloadData()
        if self.cells.isEmpty {
            self.hideDetailInfo()
            return
        }
        DispatchQueue.main.async {
            self.collectionView.selectItem(at: IndexPath(row: self.selectedIndex, section: 0), animated: true, scrollPosition: .left)
        }
    }
    
    func showActivity() {
		self.view.showLoadingIndicator()
    }

    func hideActivity() {
        HUD.find(on: self.view)?.remove()
        self.collectionView.isHidden = false
    }
}
