import XLPagerTabStrip

extension ProfileTabsViewController {
    struct Appearance: Codable {
        var mainViewBackgroundColor = Palette.shared.gray5
        var buttonBarBackgroundColor = Palette.shared.gray5
        var buttonBarItemBackgroundColor = Palette.shared.gray5
        var selectedBarBackgroundColor = Palette.shared.brown

        var oldCellLabelTextColor = Palette.shared.gray1
        var newCellLabelTextColor = Palette.shared.gray0

        var selectedBarHeight: CGFloat = 0.5
        var buttonBarItemFont = Palette.shared.primeFont.with(size: 14)
        var buttonBarMinimumLineSpacing: CGFloat = 0
        var buttonBarItemTitleColor =  Palette.shared.danger
        var barBackgroundColor = Palette.shared.gray3

        var navigationTintColor = Palette.shared.gray5
        var navigationBarGradientColors = [
            Palette.shared.brandPrimary,
            Palette.shared.brandPrimary
        ]
    }
}

final class ProfileTabsViewController: ButtonBarPagerTabStripViewController {
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
    private var profile: Profile?
    private var navigationBarShadowImage: UIImage?

    // MARK: - Lifecycle methods

	init(
		shouldPrefetchProfile: Bool = false,
		appearance: Appearance = Theme.shared.appearance()
	) {
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
		if shouldPrefetchProfile {
			_ = self.profileViewController
		}
    }

	override var preferredStatusBarStyle: UIStatusBarStyle {
		.lightContent
	}

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.setupSlidingTab()
        super.viewDidLoad()
		self.containerView.alwaysBounceHorizontal = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.shadowImage = self.navigationBarShadowImage
    }

    // MARK: - PagerTabStrip View Setup

    private func setupUI() {
        self.view.backgroundColorThemed = self.appearance.mainViewBackgroundColor
        self.navigationController?.navigationBar.tintColorThemed = self.appearance.navigationTintColor

        self.navigationItem.backButtonTitle = " "

		let favoriteImageView = UIImageView(image: UIImage(named: "favorite_icon"))
        favoriteImageView.contentMode = .center
		favoriteImageView.make(.size, .equal, [44, 44])
		favoriteImageView.addTapHandler { [weak self] in
			self?.didTapOnFavorite()
		}
        
        let settingsImageView = UIImageView(image: UIImage(named: "profile_settings_icon"))
        settingsImageView.contentMode = .center
		settingsImageView.make(.size, .equal, [44, 44])
        settingsImageView.addTapHandler { [weak self] in
            self?.didTapOnSettings()
        }
        
		let customStackView = UIStackView.horizontal(favoriteImageView, settingsImageView)
        
        let customBarButtonItem = UIBarButtonItem(customView: customStackView)
        navigationItem.rightBarButtonItem = customBarButtonItem
        
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
		self.topBarView.isHidden = true

        self.containerScrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
			make.top.equalTo(self.view.safeAreaLayoutGuide)
        }

        let shadowView = UIView()
        shadowView.backgroundColorThemed = self.appearance.barBackgroundColor

		self.view.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.selectedBarHeight)
			make.leading.trailing.equalToSuperview()
			make.top.equalTo(self.containerScrollView)
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
        self.settings.style.buttonBarItemFont = self.appearance.buttonBarItemFont.rawValue
        self.settings.style.buttonBarMinimumLineSpacing = self.appearance.buttonBarMinimumLineSpacing
        self.settings.style.buttonBarItemTitleColor = self.appearance.buttonBarItemTitleColor.rawValue
        self.settings.style.buttonBarItemsShouldFillAvailableWidth = true
    }

    private func didTapOnFavorite() {
        let viewController = PrimeTravellerWebViewController(webLink: Config.travellerEndpoint + "/personal", dismissesOnDeeplink: true)
        self.topmostPresentedOrSelf.present(viewController, animated: true)
    }
    
    private func didTapOnSettings() {
        guard let profile = self.profile else {
            return
        }
        let settingsController = ProfileSettingsAssembly(profile: profile) { [weak self] profile in
            self?.setNavBarTitle(with: profile)
            self?.profile = profile
        }.make()
        let router = PushRouter(source: self, destination: settingsController)
        router.route()
    }

    private func makeNameWithInitials(firstName: String, lastName: String) -> String {
		let lastName = String(lastName.prefix(1))
        let shortenedLastName = "\(lastName)."
        return firstName + " " + shortenedLastName
    }

    private func setNavBarTitle(with profile: Profile) {
        let title = self.makeNameWithInitials(
            firstName: profile.firstName ?? "",
            lastName: profile.lastName ?? ""
        )
        let titleLabel = UILabel()
        titleLabel.attributedTextThemed = title.attributed()
            .foregroundColor(Palette.shared.gray5)
            .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
            .string()
        self.navigationItem.titleView = titleLabel
    }

    // MARK: - PagerTabStripDataSource
	private lazy var profileViewController: UIViewController = {
		let assembly = ProfileAssembly(shouldPrefetchProfile: true) { [weak self] profile in
			guard let self = self else {
				return
			}

			self.setNavBarTitle(with: profile)
			self.profile = profile
		}

		return assembly.make()
	}()

    override func viewControllers(
        for pagerTabStripController: PagerTabStripViewController
    ) -> [UIViewController] {
        return [
			self.profileViewController
        ]
    }
}
