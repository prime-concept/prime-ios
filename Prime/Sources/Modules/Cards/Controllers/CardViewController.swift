import UIKit
import XLPagerTabStrip
import SnapKit

extension CardViewController {
    struct Appearance: Codable {
        var mainViewBackgroundColor = Palette.shared.gray5
        var buttonBarBackgroundColor = Palette.shared.gray5
        var buttonBarItemBackgroundColor = Palette.shared.gray5
        var selectedBarBackgroundColor = Palette.shared.brown

        var oldCellLabelTextColor = Palette.shared.gray1
        var newCellLabelTextColor = Palette.shared.gray0

        var selectedBarHeight: CGFloat = 0.5

        var navigationTintColor = Palette.shared.gray5
        var navigationBarGradientColors = [
            Palette.shared.brandPrimary,
            Palette.shared.brandPrimary
        ]

        var addButtonTitleColor = Palette.shared.gray0
        var addButtonBackgroundColor = Palette.shared.gray5

        var placeholderTitleColor = Palette.shared.gray0
        var placeholderSubtitleColor = Palette.shared.gray1
    }
}

protocol CardViewControllerProtocol: AnyObject {
    func update(with cards: [CardsViewModel])
    func presentForm(for type: CardEditAssembly.FormType)

    func showActivity()
    func hideActivity()
}

final class CardViewController: UIViewController {
    private let appearance: Appearance
    private let presenter: CardsPresenterProtocol
    private let tabType: CardsTabType
    private let shouldOpenInCreationMode: Bool

    private lazy var selectionPresentationManager = FloatingControllerPresentationManager(
        context: .itemSelection,
        sourceViewController: self
    )

    private lazy var addButton: UIView = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("cards.\(self.tabType.l10nType).add")
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

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColorThemed = Palette.shared.gray5
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(
            CardsTableViewCell.self,
            forCellReuseIdentifier: CardsTableViewCell.defaultReuseIdentifier
        )

        return tableView
    }()

    private lazy var placeholderView = UIView()

    private var selectedDocumentIndex: Int = 0
    private var cells: [CardsViewModel] = []
    private var viewModel: CardsViewModel?

    init(
        presenter: CardsPresenterProtocol,
        tabType: CardsTabType,
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

        self.showActivity()
        self.presenter.loadCards()
        if tabType == .loyalty {
            self.addButton.addTapHandler { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.presentForm(for: strongSelf.tabType.createFormType)
            }
            self.shouldOpenInCreationMode ? (self.presentForm(for: tabType.createFormType)) : (nil)
        }
    }

    // MARK: - Private
    private func presentSelection(with controller: UIViewController) {
		let router = ModalRouter(
			source: self,
			destination: controller,
			modalPresentationStyle: .pageSheet
		)
		router.route()
    }

    private func setupView() {
        self.view.addSubview(self.tableView)
		self.view.addSubview(self.addButton)

        self.tableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
			make.bottom.equalTo(self.addButton.snp.top)
        }
		
        self.addButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        do {
            self.placeholderView.backgroundColorThemed = Palette.shared.gray5
            self.placeholderView.isHidden = true

            let imageView = UIImageView(image: UIImage(named: "documents_add_placeholder"))
            self.placeholderView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 155, height: 135))
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-67)
            }

            let titleLabel = UILabel()
            titleLabel.attributedTextThemed = Localization.localize("cards.\(self.tabType.l10nType).empty.title")
                .attributed()
                .primeFont(ofSize: 16, lineHeight: 20)
                .alignment(.center)
                .foregroundColor(self.appearance.placeholderTitleColor)
                .string()

            let subtitleLabel = UILabel()
            subtitleLabel.attributedTextThemed = Localization.localize("cards.\(self.tabType.l10nType).empty.subtitle")
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

extension CardViewController: CardViewControllerProtocol {
    func presentForm(for type: CardEditAssembly.FormType) {
        let assembly = CardEditAssembly(type: type)
        let controller = assembly.make()
        self.presentSelection(with: controller)
    }

    func update(with cards: [CardsViewModel]) {
        self.hideActivity()
        self.cells = cards
        self.tableView.reloadData()
    }

    func showActivity() {
		self.view.showLoadingIndicator()
    }

    func hideActivity() {
        HUD.find(on: self.view)?.remove()
    }
}

extension CardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CardsTableViewCell.defaultReuseIdentifier,
            for: indexPath
        ) as? CardsTableViewCell else {
            return UITableViewCell()
        }
        cell.setup(with: cells[indexPath.row], type: tabType)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.presenter.openForm(cardIndex: indexPath.row)
    }
}

extension CardViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: Localization.localize("cards.\(self.tabType.l10nType).title"))
    }
}
