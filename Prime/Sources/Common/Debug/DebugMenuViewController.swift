import UIKit

extension Notification.Name {
	static let bugVisibilityChanged = Notification.Name("bugVisibilityChanged")
}

final class DebugMenuViewController: UIViewController {
	private lazy var vStack = UIStackView(.vertical)
	private static var isPartyModeEnabled = false
	private lazy var calendarStore = CalendarEventsService.shared

	private static func party() {
		every(0.1) {
			if self.isPartyModeEnabled {
				Palette.shared.randomize()
			}
		}
	}

	private var keyboardHeightTracker: PrimeKeyboardHeightTracker?
    private lazy var specificTasksDebouncer = Debouncer(timeout: 1.3) {
        Notification.post(.tasksUpdateRequested)
    }

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColorThemed = Palette.shared.gray5

		self.addGrabberView()

		let rcognizer = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
		self.view.addGestureRecognizer(rcognizer)
		self.view.isUserInteractionEnabled = true

		let scrollView = UIScrollView()
		scrollView.showsVerticalScrollIndicator = false
		self.view.addSubview(scrollView)
		scrollView.make(.edges, .equal, to: self.view.safeAreaLayoutGuide, [44, 20, -20, -20])

		scrollView.addSubview(self.vStack)
		self.vStack.make(.edges, .equalToSuperview)
		self.vStack.make(.width, .equal, to: self.view, -40)

		self.keyboardHeightTracker = .init(view: self.view) { height in
			scrollView.contentInset.bottom = height
		}
		
		let viewLogsButton = self.makeButton("👁️ Логи 👁️") {
			let log = DebugUtils.shared.log
			let viewer = LogViewer()
			viewer.textView.text = log
			viewer.title = "👁️ Логи 👁️"

			self.present(
				UINavigationController(rootViewController: viewer),
				animated: true,
				completion: {
					viewer.scrollToBottom()
				}
			)
		}

		let shareLogsButton = self.makeButton("✉️ Пошарить логи ✉️") {
			DebugUtils.shared.shareLog()
		}

		let sandboxButton = self.makeButton("🛠️ Песочница 🏖️") {
			let viewController = SandboxViewController()
			let nc = UINavigationController(rootViewController: viewController)
			nc.navigationBar.tintColorThemed = Palette.shared.gray0
			viewController.title = "🛠️ Песочница 🏖️"
			self.present(
				nc,
				animated: true,
				completion: nil
			)
		}

		let clearTasksButton = self.makeButton("🧹 ТАСКИ 🧹") {
			Notification.post(.shouldClearTasks)
			AlertPresenter.alert(message: "Готово!", actionTitle: "Перезапустить", cancelTitle: "Остаться", onAction: { delay(1) { exit(0) } })
		}

		let clearCacheButton = self.makeButton("🧹 КЭШ 🧹") {
			Notification.post(.shouldClearCache)
			AlertPresenter.alert(message: "Готово!", actionTitle: "OK")
		}

		let clearLogsButton = self.makeButton("🧹 ЛОГИ 🧹") {
			DebugUtils.shared.clearLog()
			AlertPresenter.alert(message: "Готово!", actionTitle: "OK")
		}

		let clearGoogleDBButton = self.makeButton("🧹 Очистить базу логов в Фаербейсе 🧹") {
			let vc = GoogleLogCleanerViewController()
			self.topmostPresentedOrSelf.present(vc, animated: true)
		}

		let randomThemeButton = self.makeButton("🎲 Случайная тема 🎲") {
			Palette.shared.randomize()
		}

		let crashButton = self.makeButton("💥 Вызвать краш! 💥") { [weak self] in
			DebugUtils.shared.log(sender: self, "Краш, вызван в \(Date())")
			fatalError("Краш, вызван в \(Date())")
		}

		let ptButton = self.makeButton("🌎 ПТПТПТ 🌎") {
			FloatingControlsView.shared.onGlobePressed?()
		}

		let clearCalendarButton = self.makeButton("🧹 Календарь (iOS + внутренний) 🧹") { [weak self] in
			self?.showLoadingIndicator()

			self?.calendarStore.clearIOSCalendar {
				self?.calendarStore.deleteAll()
				self?.hideLoadingIndicator()
			}
		}

		let switchLogView = self.makeSwitch(title: "Запись логов", isOn: Config.isLogEnabled) { pSwitch in
			Config.isLogEnabled = pSwitch.isOn
		}

		let switchPartyMode = self.makeSwitch(title: "PARTY MODE!", isOn: Self.isPartyModeEnabled) { [weak self] pSwitch in
			self?.partyModeSwitchValueChanged(pSwitch)
		}

		let hardcodedBookingPartnerId = self.makeSwitch(
			title: "BOOKING PARTNER ID\n8c29471c-...-3453774e1408",
			isOn: UserDefaults.standard.string(forKey: "hardcodedBookingPartnerId") != nil
		) { [weak self] pSwitch in
			self?.hardcodedBookingPartnerSwitched(pSwitch)
		}

		let switchProdView = self.makeSwitch(title: "Прод включен:", isOn: Config.isProdEnabled) { [weak self] pSwitch in
			self?.prodSwitchValueChanged(pSwitch)
		}

		let aeroticketsEnabled = self.makeSwitch(title: "Аэротикеты", key: "aeroticketsEnabled")
		let aeroticketsModernDates = self.makeSwitch(title: "Аэротикеты сегодн даты", key: "aeroticketsModernDates")

		let ptDebugSwitch = self.makeSwitch(title: "Дебаг ПТ", key: "ptDebugEnabled") { _ in
			Notification.post(.primeTravellerWebViewMustReload)
		}

		let branchDebugSwitch = self.makeSwitch(title: "Бранч тест:", key: "branchDebugKey") { [weak self] bSwitch in
			self?.branchDebugSwitchValueChanged(bSwitch)
		}

		let tinkoffPinSwitch = self.makeSwitch(title: "Тиньков ПИН", key: "tinkoffPinEnabled")
		let logoutIfDeletedAtFoundSwitch = self.makeSwitch(title: "Logout If Deleted At Found", key: "logoutIfDeletedAtFound")

		let switchAlertsView = self.makeSwitch(
			title: "Дебаг-алерты включены:", isOn: Config.areDebugAlertsEnabled) {
			Config.areDebugAlertsEnabled = $0.isOn
		}

		let stubRestMapsSwitch = self.makeSwitch(title: "ГуглМап в рестах", key: "googleMapRestsEnabled")
		let restUpdateTagsOnLocationChangeSwitch = self.makeSwitch(
			title: "Обн. тэгов при смене локации", key: "restUpdateTagsOnLocationChange"
		)

		let taskIDsSwitch = self.makeSwitch(title: "ТаскАйди на тасках", key: "showsTaskIdsOnTasks")
		let messageGUIDsSwitch = self.makeSwitch(title: "Гуиды на сообщениях", key: "MESSAGE_GUID_SHOWN")

		let aviaGeneralSwitch = self.makeSwitch(title: "Авиа", key: "aviaEnabled")
		let wineSwitch = self.makeSwitch(title: "Вино", key: "wineEnabled")
        
		let assistantPhoneNumberTF = self.makeTextField(title: "Телефон ассистента", key: "assistantPhoneNumber", keyboardType: .phonePad) {
            UserDefaults[string: "assistantPhoneNumber"] = (!$0.text^.isEmpty) ? $0.text : Config.assistantPhoneNumber
		}

		let clubPhoneNumberTF = self.makeTextField(title: "Телефон клуба", key: "clubPhoneNumber", keyboardType: .numbersAndPunctuation) {
			UserDefaults[string: "clubPhoneNumber"] = (!$0.text^.isEmpty) ? $0.text : Config.clubPhoneNumber
		}

		let clubWebsiteURLTF = self.makeTextField(title: "Вебсайт клуба", key: "clubWebsiteURL", keyboardType: .URL) {
			UserDefaults[string: "clubWebsiteURL"] = (!$0.text^.isEmpty) ? $0.text : Config.clubWebsiteURL
		}
        let oldestTaskDateTF = self.makeTextField(title: "Таски НЕ старше dd/MM/yyyy", key: "dropTasksOlderDate", keyboardType: .numbersAndPunctuation) {
            UserDefaults[string: "dropTasksOlderDate"] = $0.text
        }

		let tasksBatchNumberTF = self.makeTextField(title: "Размер пачки тасок", key: "TASKS_BATCH_COUNT", keyboardType: .numberPad) {
			UserDefaults[int: "TASKS_BATCH_COUNT"] = Int($0.text ?? "50") ?? 50
		}

		let backgroundLogoutTimeoutTF = self.makeTextField(title: "Секунд в фоне до разлогина", key: "backgroundLogoutTimeout", keyboardType: .numberPad) {
			UserDefaults[int: "backgroundLogoutTimeout"] = Int($0.text ?? "300") ?? 300
		}

		let travellerSplashTimeoutTF = self.makeTextField(title: "Секунд сплэша в ПТ", key: "travellerSplashTimeout", keyboardType: .numberPad) {
			UserDefaults[int: "travellerSplashTimeout"] = Int($0.text ?? "0") ?? 0
		}

		let forcedLatitudeTF = self.makeTextField(title: "Фикс широта lat", key: "TECHNOLAB_FORCED_LOCATION_LATITUDE", keyboardType: .numberPad) {
			if let value = Double($0.text ?? "") {
				UserDefaults[double: "TECHNOLAB_FORCED_LOCATION_LATITUDE"] = value
			} else {
				UserDefaults.standard.removeObject(forKey: "TECHNOLAB_FORCED_LOCATION_LATITUDE")
			}
		}

		let forcedLongitudeTF = self.makeTextField(title: "Фикс долгота long", key: "TECHNOLAB_FORCED_LOCATION_LONGITUDE", keyboardType: .numberPad) {
			if let value = Double($0.text ?? "") {
				UserDefaults[double: "TECHNOLAB_FORCED_LOCATION_LONGITUDE"] = value
			} else {
				UserDefaults.standard.removeObject(forKey: "TECHNOLAB_FORCED_LOCATION_LONGITUDE")
			}
		}

		let bugSwitch = self.makeSwitch(title: "Жук виден", key: "bugIsVisible") { _ in
			Notification.post(.bugVisibilityChanged)
		}

        let specificTasks = self.makeTextField(
            title: "Фильтр тасок",
            key: "specific_tasks_to_show"
        ) { [weak self] _ in
            self?.specificTasksDebouncer.reset()
        }

		let tasksUnreadOnly = self.makeSwitch(title: "Только непрочитанные", key: "tasksUnreadOnly") { _ in
			Notification.post(.tasksUpdateRequested)
		}

		let ptCacheDebugSwitch = self.makeSwitch(title: "Дебаг кэша ПТ", key: "PTCacheDebugEnabled") { _ in }

		let bannersSwitch = self.makeSwitch(title: "Баннеры", key: "bannersEnabled") { _ in
			Notification.post(.tasksUpdateRequested)
		}
		
        let promoCategoriesSwitch = self.makeSwitch(title: "Смежные категории", key: "promoCategoriesEnabled") { _ in
			Notification.post(.tasksUpdateRequested)
		}

		let taskTapAreasSwitch = self.makeSwitch(title: "Области тапов у таски", key: "taskTapAreasEnabled") { _ in
			Notification.post(.tasksUpdateRequested)
		}

		let addressTapSwitch = self.makeSwitch(title: "Тап на адрес", key: "addressTapEnabled") { _ in
			Notification.post(.tasksUpdateRequested)
		}

        let walletSwitch = self.makeSwitch(title: "Wallet", key: "addToWalletEnabled") { _ in
			Notification.post(.profileDataRequested)
		}

		let vipLoungeSwitch = self.makeSwitch(title: "VIP Lounge", key: "vipLoungeEnabled") { _ in
			Notification.post(.tasksUpdateRequested)
		}

		let appLabel = UILabel { (label: UILabel) in
			label.textAlignment = .center
			label.text = "\(Bundle.main.appName) \(Bundle.main.releaseVersionNumberPretty)"
		}

		let logOutButton = self.makeButton("🚪➡️", Palette.shared.gray5) { [weak self] in
			Notification.post(.loggedOut)
			self?.clearCacheAndTasks()
		}

		logOutButton.make(.width, .greaterThanOrEqual, 44)
		logOutButton.make(.height, .equal, 44)
		logOutButton.backgroundColor = .red
		logOutButton.isHidden = !LocalAuthService.shared.isAuthorized

		let userIdTF = self.makeTextField(
			title: "Username",
			value: LocalAuthService.shared.user?.username,
			keyboardType: .phonePad
		) {
			guard let text = $0.text else { return }
			self.updateProfile(username: text)
		}
		
		let tokenTF = self.makeTextField(
			title: "Access Token",
			value: LocalAuthService.shared.token?.accessToken
		) { [weak self] in
			guard let text = $0.text else { return }
			self?.updateToken(access: text)
		}
		
		let refreshTokenTF = self.makeTextField(
			title: "Refresh Token",
			value: LocalAuthService.shared.token?.refreshToken
		) { [weak self] in
			guard let text = $0.text else { return }
			self?.updateToken(refresh: text)
		}
		
		let pincodeTF = self.makeTextField(
			title: "Pincode",
			value: LocalAuthService.shared.pinCode
		) {
			guard let text = $0.text else { return }
			LocalAuthService.shared.pinCode = text
		}

		self.vStack.addArrangedSubview(appLabel)
		self.vStack.addArrangedSubview(userIdTF)
        self.vStack.addArrangedSubview(pincodeTF)
        self.vStack.addArrangedSubview(UIStackView.horizontal(tokenTF, .vSpacer(growable: 10), logOutButton))
        self.vStack.addArrangedSubview(refreshTokenTF)
		self.vStack.addArrangedSubview(aeroticketsEnabled)
		self.vStack.addArrangedSubview(aeroticketsModernDates)
		self.vStack.addArrangedSubview(ptButton)
		self.vStack.addArrangedSubview(switchProdView)
		self.vStack.addArrangedSubview(tinkoffPinSwitch)
		self.vStack.addArrangedSubview(logoutIfDeletedAtFoundSwitch)
		self.vStack.addArrangedSubview(branchDebugSwitch)
		self.vStack.addArrangedSubview(bugSwitch)
		self.vStack.addArrangedSubview(tasksUnreadOnly)
        self.vStack.addArrangedSubview(oldestTaskDateTF)
        self.vStack.addArrangedSubview(specificTasks)
		self.vStack.addArrangedSubview(assistantPhoneNumberTF)
		self.vStack.addArrangedSubview(clubPhoneNumberTF)
		self.vStack.addArrangedSubview(clubWebsiteURLTF)
		self.vStack.addArrangedSubview(forcedLatitudeTF)
		self.vStack.addArrangedSubview(forcedLongitudeTF)
		self.vStack.addArrangedSubview(taskIDsSwitch)
		self.vStack.addArrangedSubview(messageGUIDsSwitch)
		self.vStack.addArrangedSubview(vipLoungeSwitch)
		self.vStack.addArrangedSubview(walletSwitch)
		self.vStack.addArrangedSubview(taskTapAreasSwitch)
		self.vStack.addArrangedSubview(addressTapSwitch)
		self.vStack.addArrangedSubview(bannersSwitch)
		self.vStack.addArrangedSubview(promoCategoriesSwitch)
		self.vStack.addArrangedSubview(ptDebugSwitch)
		self.vStack.addArrangedSubview(ptCacheDebugSwitch)
		self.vStack.addArrangedSubview(switchAlertsView)
		self.vStack.addArrangedSubview(switchLogView)
		self.vStack.addArrangedSubview(switchPartyMode)
		self.vStack.addArrangedSubview(hardcodedBookingPartnerId)
		self.vStack.addArrangedSubview(restUpdateTagsOnLocationChangeSwitch)
		self.vStack.addArrangedSubview(stubRestMapsSwitch)
		self.vStack.addArrangedSubview(aviaGeneralSwitch)
		self.vStack.addArrangedSubview(wineSwitch)
		self.vStack.addArrangedSubview(tasksBatchNumberTF)
		self.vStack.addArrangedSubview(backgroundLogoutTimeoutTF)
		self.vStack.addArrangedSubview(travellerSplashTimeoutTF)

		self.vStack.addArrangedSubview(UIStackView.horizontal(
			viewLogsButton, .hSpacer(growable: 0), shareLogsButton)
		)
		self.vStack.addArrangedSubview(
			UIStackView { (stack: UIStackView) in
				stack.alignment = .center
				stack.distribution = .equalSpacing
				stack.addArrangedSubviews(clearTasksButton, clearLogsButton, clearCacheButton)
			}
		)
		self.vStack.addArrangedSubview(clearGoogleDBButton)
		self.vStack.addArrangedSubview(clearCalendarButton)
		self.vStack.addArrangedSubview(randomThemeButton)
		self.vStack.addArrangedSubview(crashButton)
		self.vStack.addArrangedSubview(sandboxButton)

//		self.placeTestGradientLayer()
	}

	private func makeCopyingLabel(_ title: String, _ text: String?) -> UILabel {
		let label = UILabel { (label: UILabel) in
			label.numberOfLines = 0
			label.lineBreakMode = .byWordWrapping
			label.text = "\(title) (tap!): \(text ?? "")"
			label.isHidden = text == nil
			label.addTapHandler {
				UIPasteboard.general.string = text
				label.text = "\(title) (copied!): \(text ?? "")"
				delay(2) { label.text = "\(title) (tap!): \(text ?? "")" }
			}
		}
		label.make(.height, .greaterThanOrEqual, 44)
		return label
	}

	private func makeSwitch(title: String, key: String? = nil, isOn: Bool? = nil, handler: ((UISwitch) -> Void)? = nil) -> UIView {
		let view = UIView()

		let label = UILabel()
		label.attributedTextThemed = title
			.attributed()
			.font(Palette.shared.primeFont)
			.foregroundColor(Palette.shared.gray0)
			.lineBreakMode(.byWordWrapping)
			.string()

		label.numberOfLines = 2
		label.lineBreakMode = .byWordWrapping

		view.addSubview(label)

		let pSwitch = UISwitch()
		pSwitch.onTintColorThemed = Palette.shared.brandPrimary
		pSwitch.thumbTintColorThemed = Palette.shared.gray5
		if let key = key {
			pSwitch.isOn = UserDefaults[bool: key]
			pSwitch.setEventHandler(for: .valueChanged) {
				UserDefaults[bool: key] = pSwitch.isOn
				handler?(pSwitch)
			}
		} else if let isOn = isOn {
			pSwitch.isOn = isOn
			pSwitch.setEventHandler(for: .valueChanged) {
				handler?(pSwitch)
			}
		}

		view.addSubview(pSwitch)

		label.make([.leading, .centerY], .equalToSuperview)
		pSwitch.make([.trailing, .centerY], .equalToSuperview, [-5, 0])
		view.make(.height, .equal, 44)

		return view
	}

	private func makeTextField(
		title: String,
        value: String? = nil,
		key: String? = nil,
        userDefaults: UserDefaults = .standard,
		keyboardType: UIKeyboardType = .default,
		handler: ((UITextField) -> Void)? = nil
	) -> UIView {
		let view = UIView()

		let label = UILabel()
		label.attributedTextThemed = title
			.attributed()
			.font(Palette.shared.primeFont)
			.foregroundColor(Palette.shared.gray0)
			.lineBreakMode(.byWordWrapping)
			.string()

		label.numberOfLines = 2
		label.lineBreakMode = .byWordWrapping

        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

		view.addSubview(label)

		let textField = UITextField()
        textField.text = value

		if let key = key {
            textField.text = userDefaults.string(forKey: key)
		}

		textField.setEventHandler(for: .editingChanged) {
			if let key = key {
                userDefaults.setValue(textField.text, forKey: key)
			}
            handler?(textField)
		}

		textField.keyboardType = keyboardType
		textField.layer.borderWidth = 1
		textField.layer.cornerRadius = 2
		textField.layer.borderColorThemed = Palette.shared.brandPrimary
		textField.textColorThemed = Palette.shared.mainBlack

		textField.textAlignment = .center

		view.addSubview(textField)

		label.make([.leading, .centerY], .equalToSuperview)

		textField.make([.trailing, .centerY, .height], .equalToSuperview, [-5, 0, -12])
		textField.make(.leading, .equal, to: .trailing, of: label, +10)
		textField.make(.width, .greaterThanOrEqual, 44)

        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

		view.make(.height, .equal, 44)

		return view
	}

	private func placeTestGradientLayer() {
		let layer = CAGradientLayer()
		layer.colorsThemed = [Palette.shared.custom_gray6, Palette.shared.gray0]
		layer.startPoint = CGPoint(x: 0.5, y: 0)
		layer.endPoint = CGPoint(x: 0.5, y: 1)
		layer.frame = CGRect(x: 20, y: 540, width: 150, height: 150)
		self.view.layer.addSublayer(layer)
		layer.masksToBounds = false

		layer.borderColorThemed = Palette.shared.brandPrimary
		layer.borderWidth = 10
		layer.shadowColorThemed = Palette.shared.black
		layer.shadowRadius = 10
		layer.shadowOpacity = 0.2
		layer.shadowOffset = CGSize(width: 10, height: 10)
	}

	@objc
	private func prodSwitchValueChanged(_ prodSwitch: UISwitch) {
		let alert = UIAlertController(title: "Смена параметров",
									  message: "Приложение будет закрыто для применения новых параметров",
									  preferredStyle: .alert)
		alert.addAction(.init(title: "Отмена", style: .cancel, handler: { _ in
			prodSwitch.isOn = !prodSwitch.isOn
		}))
		alert.addAction(.init(title: "Закрыть", style: .destructive) { [weak self] _ in
			Config.isProdEnabled = prodSwitch.isOn
			UserDefaults[bool: "branchDebugKey"] = !prodSwitch.isOn
			LocalAuthService.shared.removeAuthorization()
			Notification.post(.loggedOut)
			self?.clearCacheAndTasks()
			delay(1) {
				exit(1)
			}
		})
		self.present(alert, animated: true, completion: nil)
	}

	@objc
	private func branchDebugSwitchValueChanged(_ branchSwitch: UISwitch) {
		let alert = UIAlertController(title: "Переключение бранч кея",
									  message: "Приложение будет закрыто для применения новых параметров",
									  preferredStyle: .alert)
		alert.addAction(.init(title: "Отмена", style: .cancel, handler: { _ in
			branchSwitch.isOn = !branchSwitch.isOn
		}))
		alert.addAction(.init(title: "Закрыть", style: .destructive) { _ in
			UserDefaults[bool: "branchDebugKey"] = branchSwitch.isOn
			delay(1) {
				exit(1)
			}
		})
		self.present(alert, animated: true, completion: nil)
	}

	@objc
	private func partyModeSwitchValueChanged(_ sswitch: UISwitch) {
		Self.isPartyModeEnabled = sswitch.isOn
		if Self.isPartyModeEnabled {
			Self.party()
		} else {
			delay(0.25) {
				Palette.shared.restore()
			}
		}
	}

	@objc
	private func hardcodedBookingPartnerSwitched(_ sswitch: UISwitch) {
		let value: String? = sswitch.isOn ? "8c29471c-6392-4ef6-9d60-3453774e1408" : nil
		UserDefaults.standard.set(value, forKey: "hardcodedBookingPartnerId")
	}

	private func addGrabberView() {
		let grabberView = UIView()
		grabberView.layer.cornerRadius = 2
		grabberView.backgroundColorThemed = Palette.shared.gray3
		self.view.addSubview(grabberView)
		grabberView.snp.makeConstraints { make in
			make.centerX.equalToSuperview()
			make.size.equalTo(CGSize(width: 36, height: 4))
			make.top.equalToSuperview().offset(10)
		}
	}

	private func makeButton(
		_ title: String,
		_ titleColor: ThemedColor = Palette.shared.gray0,
		action: (() -> Void)?
	) -> UIButton {
		let button = UIButton(type: .custom)
		button.make(.height, .equal, 44)
		button.setAttributedTitle(title.attributed().font(Palette.shared.primeFont)
										.foregroundColor(titleColor)
										.alignment(.left)
										.string(),
									   for: .normal)
		button.setEventHandler(for: .touchUpInside, action: action)

		return button
	}

	private func updateToken(access: String? = nil, refresh: String? = nil) {
		var token = LocalAuthService.shared.token ?? .empty

		if let access {
			token.accessToken = access
		}

		if let refresh {
			token.refreshToken = refresh
		}

		LocalAuthService.shared.update(token: token)

		self.clearCacheAndTasks()
	}

	private func updateProfile(username: String) {
		var user = LocalAuthService.shared.user ?? .empty
		
		user.username = username
		LocalAuthService.shared.update(user: user)

		ProfileService.shared.update(profile: user)

		self.clearCacheAndTasks()
	}

	private func clearCacheAndTasks() {
		Notification.post(.shouldClearCache)
		Notification.post(.shouldClearTasks)
	}
}

extension DebugMenuViewController {
	static func show() {
		guard let topVC = UIApplication.shared
			.keyWindow?
			.rootViewController?
			.topmostPresentedOrSelf else {
			return
		}

		if topVC is DebugMenuViewController {
			return
		}

		let debugMenu = DebugMenuViewController()
		topVC.present(debugMenu, animated: true, completion: nil)
	}
}
