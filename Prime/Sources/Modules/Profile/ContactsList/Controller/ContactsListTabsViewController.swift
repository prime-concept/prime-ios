import XLPagerTabStrip
import UIKit

extension ContactsListTabsViewController {
    struct Appearance: Codable {
        var mainViewBackgroundColor = Palette.shared.gray5
        var buttonBarBackgroundColor = Palette.shared.gray5
        var buttonBarItemBackgroundColor = Palette.shared.gray5
        var selectedBarBackgroundColor = Palette.shared.gray0

        var oldCellLabelTextColor = Palette.shared.systemLightGray
        var newCellLabelTextColor = Palette.shared.gray0

        var selectedBarHeight: CGFloat = 0.5
        var buttonBarItemFont = Palette.shared.primeFont.with(size: 14)
        var buttonBarMinimumLineSpacing: CGFloat = 0
        var buttonBarItemTitleColor =  Palette.shared.danger

        var navigationTintColor = Palette.shared.gray5
        var navigationBarGradientColors = [
            Palette.shared.brandPrimary,
            Palette.shared.brandPrimary
        ]
    }
}

final class ContactsListTabsViewController: ButtonBarPagerTabStripViewController {
    lazy var topBarView: ButtonBarView = {
        let view = ButtonBarView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var containerScrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let appearance: Appearance
    private let indexToMove: Int?
    private let tabsControllers: [UIViewController]
    private var navigationBarShadowImage: UIImage?

    // MARK: - Lifecycle methods

    init(controllers: [UIViewController], indexToMove: Int?, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        self.indexToMove = indexToMove
        self.tabsControllers = controllers
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
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
            label.attributedTextThemed = Localization.localize("profile.contacts").attributed()
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
            make.height.equalTo(46)
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(5)
            make.leading.trailing.equalToSuperview()
        }

        self.containerScrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.topBarView.snp.bottom)
        }

		let themeUpdateHandler = { [weak self] in
			guard let self = self else {
				return
			}
			self.settings.style.buttonBarBackgroundColor = self.appearance.buttonBarBackgroundColor.rawValue
			self.settings.style.buttonBarItemBackgroundColor = self.appearance.buttonBarItemBackgroundColor.rawValue
			self.settings.style.selectedBarBackgroundColor = self.appearance.selectedBarBackgroundColor.rawValue
			self.settings.style.buttonBarItemTitleColor = self.appearance.buttonBarItemTitleColor.rawValue
		}

		Notification.onReceive(.paletteDidChange) { _ in
			themeUpdateHandler()
		}

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

		themeUpdateHandler()

        self.settings.style.selectedBarHeight = self.appearance.selectedBarHeight
		self.settings.style.buttonBarItemFont = self.appearance.buttonBarItemFont.rawValue
        self.settings.style.buttonBarMinimumLineSpacing = self.appearance.buttonBarMinimumLineSpacing
        self.settings.style.buttonBarItemsShouldFillAvailableWidth = true
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(
        for pagerTabStripController: PagerTabStripViewController
    ) -> [UIViewController] {
        self.tabsControllers
    }
}
