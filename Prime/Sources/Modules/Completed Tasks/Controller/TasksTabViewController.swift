import XLPagerTabStrip

extension TasksTabViewController {
    struct Appearance: Codable {
        var grabberViewBackgroundColor = Palette.shared.gray3
        var mainViewBackgroundColor = Palette.shared.gray5

        var buttonBarBackgroundColor = Palette.shared.gray5
        var buttonBarItemBackgroundColor = Palette.shared.gray5
        var selectedBarBackgroundColor = Palette.shared.gray0

		var oldCellLabelTextColor = Palette.shared.systemLightGray
        var newCellLabelTextColor = Palette.shared.gray0

        var selectedBarHeight: CGFloat = 0.5
        var buttonBarItemFont = Palette.shared.primeFont.with(size: 14)
        var buttonBarMinimumLineSpacing: CGFloat = 0
		var buttonBarItemTitleColor = Palette.shared.danger
    }
}

class TasksTabViewController: ButtonBarPagerTabStripViewController {
    enum TasksTabType {
        case pay
        case completed
		case all
    }

    lazy var grabberView: UIView = {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 36, height: 4))
        }
		view.layer.cornerRadius = 2
        view.backgroundColorThemed = self.appearance.grabberViewBackgroundColor
        return view
    }()

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

    private let appearance: Appearance
    private let tabType: TasksTabType

    init(type: TasksTabType, appearance: Appearance = Theme.shared.appearance()) {
        self.tabType = type
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.setupSlidingTab()
        self.view.backgroundColorThemed = self.appearance.mainViewBackgroundColor
        super.viewDidLoad()
    }

    // MARK: - PagerTabStrip View Setup

    private func setupSlidingTab() {
        self.containerView = self.containerScrollView
        self.buttonBarView = self.topBarView

        self.view.addSubview(self.grabberView)
        self.view.addSubview(self.topBarView)
        self.view.addSubview(self.containerScrollView)

        self.grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }

        self.topBarView.snp.makeConstraints { make in
            let height = self.topBarView.isHidden ? 0 : 44
            make.height.equalTo(height)
            make.top.equalTo(self.grabberView).offset(5)
            make.leading.trailing.equalToSuperview()
        }

        self.containerScrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
			make.top.equalTo(self.topBarView.snp.bottom).offset(15)
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
            guard changeCurrentIndex else {
                return
            }
            oldCell?.label.textColorThemed = self.appearance.oldCellLabelTextColor
            newCell?.label.textColorThemed = self.appearance.newCellLabelTextColor
        }
        self.settings.style.selectedBarHeight = self.appearance.selectedBarHeight
		self.settings.style.buttonBarItemFont = self.appearance.buttonBarItemFont.rawValue
        self.settings.style.buttonBarMinimumLineSpacing = self.appearance.buttonBarMinimumLineSpacing
		self.settings.style.buttonBarItemTitleColor = self.appearance.buttonBarItemTitleColor.rawValue
        self.settings.style.buttonBarItemsShouldFillAvailableWidth = true
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(
        for pagerTabStripController: PagerTabStripViewController
    ) -> [UIViewController] {
        switch self.tabType {
        case .pay:
            let toPayViewController = TasksListAssembly(type: .waitingForPayment).make()
            return [toPayViewController]
        case .completed:
            let historyViewController = TasksListAssembly(type: .completed).make()
            return [historyViewController]
		case .all:
			let allTasksViewController = TasksListAssembly(type: .all).make()
			return [allTasksViewController]
        }
    }
}
