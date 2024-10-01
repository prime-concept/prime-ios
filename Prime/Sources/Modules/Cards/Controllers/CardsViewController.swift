import UIKit
import XLPagerTabStrip

extension CardsViewController {
    struct Appearance: Codable {
        var mainViewBackgroundColor = Palette.shared.gray5
        var buttonBarBackgroundColor = Palette.shared.gray5
        var buttonBarItemBackgroundColor = Palette.shared.gray5
        var selectedBarBackgroundColor = Palette.shared.brown
        var barBackgroundColor = Palette.shared.gray3

        var oldCellLabelTextColor = Palette.shared.gray1
        var newCellLabelTextColor = Palette.shared.gray0

        var selectedBarHeight: CGFloat = 0.5

        var navigationTintColor = Palette.shared.gray5
        var navigationBarGradientColors = [
            Palette.shared.brandPrimary,
            Palette.shared.brandPrimary
        ]
        var placeholderTitleColor = Palette.shared.gray0
        var placeholderSubtitleColor = Palette.shared.gray1
    }
}

final class CardsViewController: ButtonBarPagerTabStripViewController {
    lazy var topBarView: ButtonBarView = {
        let view = ButtonBarView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var containerScrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let indexToMove: Int?
    private let appearance: Appearance
    private var navigationBarShadowImage: UIImage?
    private let tabsControllers: [UIViewController]

    // MARK: - Lifecycle methods

    init(controllers: [UIViewController], indexToMove: Int?, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        self.tabsControllers = controllers
        self.indexToMove = indexToMove
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
        self.setupSlidingTab()
        super.viewDidLoad()
        self.setupUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        guard let index = self.indexToMove else {
            return
        }
        self.moveToViewController(at: index, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.navigationBar.shadowImage = self.navigationBarShadowImage
    }

    // MARK: - PagerTabStrip View Setup

    private func setupUI() {
        self.navigationItem.titleView = { () -> UIView in
            let label = UILabel()
            label.attributedTextThemed = Localization.localize("cards.title").attributed()
                .foregroundColor(self.appearance.navigationTintColor)
                .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
                .string()
            return label
        }()

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

    private func setupSlidingTab() {
        self.containerView = self.containerScrollView
        self.buttonBarView = self.topBarView

        self.view.addSubview(self.topBarView)
        self.view.addSubview(self.containerScrollView)
        self.topBarView.snp.makeConstraints { make in
            let height = self.topBarView.isHidden ? 0 : 46
            make.height.equalTo(height)
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(5)
            make.leading.trailing.equalToSuperview()
        }

        let shadowView = UIView()
        shadowView.backgroundColorThemed = self.appearance.barBackgroundColor

        self.view.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.selectedBarHeight)
            make.bottom.equalTo(self.buttonBarView.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        self.containerScrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.topBarView.snp.bottom)
        }

		self.settings.style.buttonBarBackgroundColor = self.appearance.buttonBarBackgroundColor.rawValue
        self.settings.style.buttonBarItemBackgroundColor = self.appearance.buttonBarItemBackgroundColor.rawValue
        self.settings.style.selectedBarBackgroundColor = self.appearance.selectedBarBackgroundColor.rawValue

        self.changeCurrentIndexProgressive = { (
            oldCell: ButtonBarViewCell?,
            newCell: ButtonBarViewCell?,
            progressPercentage: CGFloat,
            changeCurrentIndex: Bool,
            animated: Bool
        ) -> Void in
            guard changeCurrentIndex == true else {
                return
            }
            oldCell?.label.textColorThemed = self.appearance.oldCellLabelTextColor
            newCell?.label.textColorThemed = self.appearance.newCellLabelTextColor
        }

        self.settings.style.selectedBarHeight = self.appearance.selectedBarHeight
		self.settings.style.buttonBarItemFont = Palette.shared.primeFont.with(size: 14).rawValue
        self.settings.style.buttonBarMinimumLineSpacing = 0
        self.settings.style.buttonBarItemsShouldFillAvailableWidth = true
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(
        for pagerTabStripController: PagerTabStripViewController
    ) -> [UIViewController] {
        self.tabsControllers
    }
}
