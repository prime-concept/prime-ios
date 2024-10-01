import UIKit
import XLPagerTabStrip
import SnapKit

extension DocumentViewController {
    struct Appearance: Codable {
        var mainViewBackgroundColor = Palette.shared.gray5
        var selectedBarBackgroundColor = Palette.shared.brown

        var oldCellLabelTextColor = Palette.shared.gray1
        var newCellLabelTextColor = Palette.shared.gray0

        var selectedBarHeight: CGFloat = 0.5

        var navigationTintColor = Palette.shared.gray5
        var navigationBarGradientColors = [
            Palette.shared.brandPrimary,
            Palette.shared.brandPrimary
        ]

		var editButtonBackgroundColor = Palette.shared.gray5
        var editButtonTitleColor = Palette.shared.gray0
        var addButtonTitleColor = Palette.shared.gray5
        var addButtonBackgroundColor = Palette.shared.brandPrimary

        var placeholderTitleColor = Palette.shared.gray0
        var placeholderSubtitleColor = Palette.shared.gray1
    }
}

protocol DocumentViewControllerProtocol: AnyObject {
    func update(with documents: [DocumentViewModel])
    func presentForm(for type: DocumentEditAssembly.FormType, personId: Int?)

    func showActivity()
    func hideActivity()
}

final class DocumentViewController: UIViewController {
    private let appearance: Appearance
    private let presenter: DocumentPresenterProtocol
    private let tabType: DocumentTabType
    private let shouldOpenInCreationMode: Bool

    private lazy var editButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("documents.\(self.tabType.l10nType).edit")
            .attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .alignment(.center)
            .foregroundColor(self.appearance.editButtonTitleColor)
            .string()

        label.clipsToBounds = true
        label.layer.cornerRadius = 8

        label.layer.borderColorThemed = Palette.shared.gray3
        label.layer.borderWidth = 1 / UIScreen.main.scale

		label.backgroundColorThemed = self.appearance.editButtonBackgroundColor

        return label
    }()

	// Yep. In new design iteration, look and feel of add button is similar to edit button.
    private lazy var addButton: UIView = {
		let label = UILabel()
		label.attributedTextThemed = Localization.localize("documents.\(self.tabType.l10nType).add")
			.attributed()
			.primeFont(ofSize: 16, lineHeight: 18)
			.alignment(.center)
			.foregroundColor(self.appearance.editButtonTitleColor)
			.string()

		label.clipsToBounds = true
		label.layer.cornerRadius = 8

		label.layer.borderColorThemed = Palette.shared.gray3
		label.layer.borderWidth = 1 / UIScreen.main.scale

		label.backgroundColorThemed = self.appearance.editButtonBackgroundColor

        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColorThemed = Palette.shared.gray5

        collectionView.register(cellClass: DocumentInfoTypeCarouselCollectionViewCell.self)
        collectionView.register(cellClass: DocumentInfoEmptySpaceCollectionViewCell.self)
        collectionView.register(cellClass: DocumentInfoSeparatorCollectionViewCell.self)
        collectionView.register(cellClass: DocumentInfoGeneralCollectionViewCell.self)
        collectionView.register(cellClass: DocumentInfoOneColumnCollectionViewCell.self)
        collectionView.register(cellClass: DocumentInfoTwoColumnCollectionViewCell.self)

        return collectionView
    }()

    private lazy var placeholderView = UIView()

    private var documents: [DocumentViewModel] = []
    private var selectedDocumentIndex: Int = 0
    private var cells: [DocumentInfoCell] = []

    init(
        presenter: DocumentPresenterProtocol,
        tabType: DocumentTabType,
        appearance: Appearance = Theme.shared.appearance(),
        shouldOpenInCreationMode: Bool = false
    ) {
        self.appearance = appearance
        self.presenter = presenter
        self.tabType = tabType
        self.shouldOpenInCreationMode = shouldOpenInCreationMode
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.editButton.addTapHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.presenter.openForm(documentIndex: strongSelf.selectedDocumentIndex)
        }

        self.addButton.addTapHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.presentForm(
                for: strongSelf.tabType.createFormType,
                personId: strongSelf.presenter.retrievePersonID()
            )
        }
        delay(1) {
            self.shouldOpenInCreationMode ? (
                self.presentForm(
                    for: self.tabType.createFormType,
                    personId: self.presenter.retrievePersonID()
                )
            ) : (nil)
        }
        self.presenter.loadDocuments()
    }

    // MARK: - Private

    private func display(with index: Int) {
        guard let document = self.documents[safe: index] else {
            return
        }

        self.selectedDocumentIndex = index

        var cells: [DocumentInfoCell] = [
            .typeCarousel,
            .separator,
            .emptySpace(15)
        ]

        cells.append(contentsOf: document.cells)
        self.cells = cells
        self.collectionView.reloadData()
    }

    private func setupView() {
        self.view.addSubview(self.collectionView)
		self.view.addSubview(self.editButton)
        self.collectionView.snp.makeConstraints { make in
			make.top.leading.trailing.equalToSuperview()
			make.bottom.equalTo(self.editButton.snp.top)
        }

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.editButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        self.view.addSubview(self.addButton)
        self.addButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        var insets = self.collectionView.contentInset
        insets.bottom = 44 + 20
        self.collectionView.contentInset = insets

        do {
            self.placeholderView.backgroundColorThemed = Palette.shared.gray5
            self.placeholderView.isHidden = true

            let imageView = UIImageView(image: UIImage(named: "documents_\(self.tabType.l10nType)_placeholder"))
            self.placeholderView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 155, height: 135))
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-67)
            }

            let titleLabel = UILabel()
            titleLabel.attributedTextThemed = Localization.localize("documents.\(self.tabType.l10nType).empty.title")
                .attributed()
                .primeFont(ofSize: 16, lineHeight: 20)
                .alignment(.center)
                .foregroundColor(self.appearance.placeholderTitleColor)
                .string()

            let subtitleLabel = UILabel()
            subtitleLabel.numberOfLines = 0
            subtitleLabel.attributedTextThemed = Localization.localize("documents.\(self.tabType.l10nType).empty.subtitle")
                .attributed()
                .primeFont(ofSize: 13, lineHeight: 16)
                .alignment(.center)
                .foregroundColor(self.appearance.placeholderSubtitleColor)
                .string()

            self.placeholderView.addSubview(titleLabel)
            self.placeholderView.addSubview(subtitleLabel)

            titleLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(45)
                make.top.equalTo(imageView.snp.bottom).offset(10)
            }

            subtitleLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(45)
                make.top.equalTo(titleLabel.snp.bottom).offset(5)
            }

            self.view.addSubview(self.placeholderView)
            self.placeholderView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.addButton.snp.top)
            }
        }
    }
}

extension DocumentViewController: DocumentViewControllerProtocol {
    func update(with documents: [DocumentViewModel]) {
        self.addButton.isHidden = !documents.isEmpty
        self.editButton.isHidden = documents.isEmpty
        self.placeholderView.isHidden = !documents.isEmpty

        if self.documents.count > documents.count {
            let isFirstDocumentSelected = self.selectedDocumentIndex == 0
            self.selectedDocumentIndex = isFirstDocumentSelected ? 0 : self.selectedDocumentIndex - 1
        }

        self.documents = documents

        self.hideActivity()

        if documents.isEmpty {
            self.collectionView.reloadData()
        } else {
            self.display(with: self.selectedDocumentIndex)
        }
    }

    func presentForm(for type: DocumentEditAssembly.FormType, personId: Int?) {
        // Any visa should be attached to valid passport
        let isValidPassport: (Document) -> Bool = {
            $0.documentType == .passport && $0.documentNumber != nil && $0.id != nil
        }
        if let personId = personId {
            let availablePassports = FamilyDocumentsService.shared.documents?.filter(isValidPassport)
            if case .newVisa = type, let passports = availablePassports, passports.isEmpty {
                let alert = AlertContollerFactory.makeAlert(with: "documents.visa.requirement".localized)
                self.presentModal(controller: alert)
                return
            }

            let controller = PersonDocumentEditAssembly(type: type, personId: personId).make()
            self.presentModal(controller: controller)
        } else {
            let availablePassports = DocumentsService.shared.documents?.filter(isValidPassport)
            if case .newVisa = type, let passports = availablePassports, passports.isEmpty {
                let alert = AlertContollerFactory.makeAlert(with: "documents.visa.requirement".localized)
                self.presentModal(controller: alert)
                return
            }

            let controller = DocumentEditAssembly(type: type).make()
            self.presentModal(controller: controller)
        }
    }

    func showActivity() {
		self.view.showLoadingIndicator()
    }

    func hideActivity() {
        HUD.find(on: self.view)?.remove()
    }
}

extension DocumentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.cells.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let item = self.cells[indexPath.item]

        switch item {
        case .typeCarousel:
            let cell: DocumentInfoTypeCarouselCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(
                with: self.documents.map(\.documentType),
                selectedIndex: self.selectedDocumentIndex,
                onSelect: { [weak self] idx in
                    guard let strongSelf = self else {
                        return
                    }

                    guard strongSelf.selectedDocumentIndex != idx else {
                        return
                    }

                    if idx == strongSelf.documents.count {
                        strongSelf.presentForm(
                            for: strongSelf.tabType.createFormType,
                            personId: strongSelf.presenter.retrievePersonID()
                        )
                    } else {
                        strongSelf.display(with: idx)
                    }
                }
            )
            return cell

        case .emptySpace:
            let cell: DocumentInfoEmptySpaceCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell

        case .separator:
            let cell: DocumentInfoSeparatorCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell

        case .general(let name, let number):
            let cell: DocumentInfoGeneralCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: name, number: number)
            return cell

        case .oneColumn(let title, let text):
            let cell: DocumentInfoOneColumnCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: title, text: text)
            return cell

        case .twoColumn(let left, let right):
            let cell: DocumentInfoTwoColumnCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configure(with: left, rightColumn: right)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let item = self.cells[indexPath.item]
        let height = item.cellHeight(collectionView.bounds.width)

        return CGSize(width: collectionView.bounds.width, height: height)
    }
}

extension DocumentViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: Localization.localize("documents.\(self.tabType.l10nType).title"))
    }
}
