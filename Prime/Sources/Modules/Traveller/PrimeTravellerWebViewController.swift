import UIKit
import WebKit
import CoreLocation

extension Notification.Name {
	static let primeTravellerWebViewMustReload = Notification.Name("primeTravellerWebViewMustReload")
}

final class PrimeTravellerWebViewController: UIViewController {
	private lazy var grabberView = with(UIView()) { view in
		view.backgroundColorThemed = Palette.shared.gray3
		view.layer.cornerRadius = 1.5
	}

	private lazy var webView = WKWebView(
		frame: UIScreen.main.bounds,
		configuration: with(WKWebViewConfiguration()){ config in
			config.suppressesIncrementalRendering = true
	})

	private lazy var cacheSplashWebView = WKWebView(
		frame: UIScreen.main.bounds,
		configuration: with(WKWebViewConfiguration()){ config in
			config.suppressesIncrementalRendering = true
	})

	private var cachedContentIsLoadedIntoSplash = false
	private var mayShowError = false
	private var needsLoadingSplash: Bool = false

	private let utm = "utm_source=\(Config.utmSource)&utm_medium=mobile_application&utm_campaign=prime_travel_user_landing_from_app_integrated"
	
	private var timesContentLoaded = 0

	var webLink = "" {
		didSet {
			self.timesContentLoaded = 0
			self.showLoadingIndicatorIfNeeded()
			self.loadWebContent()
		}
	}

	private var dismissesOnDeeplink = true
	private var shouldForceNextReload = false

	private var latestLocation: CLLocationCoordinate2D?

	init() {
		self.needsLoadingSplash = true
		super.init(nibName: nil, bundle: nil)
		self.subscribeToNotifications()
	}
    
	convenience init(
		webLink: String,
		dismissesOnDeeplink: Bool = true
	) {
		self.init()
        self.webLink = webLink
		self.dismissesOnDeeplink = dismissesOnDeeplink
    }

	private func subscribeToNotifications() {
		Notification.onReceive(.networkReachabilityChanged) { [weak self] notification in
			let isConnected = notification.userInfo?["value"] as? Bool
			if let isConnected = isConnected, isConnected == true {
				self?.loadWebContent()
			}
		}

		Notification.onReceive(.didRefreshToken) { [weak self] _ in
			self?.latestLocation = nil // reset location to ensure reload
			self?.loadWebContent()
		}

		Notification.onReceive(UIApplication.didBecomeActiveNotification) { [weak self] _ in
			guard let self = self, self.timesContentLoaded > 0 else {
				return
			}
			self.loadWebContent()
		}
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.placeWebView()
		self.placeSplash()
		self.placeGrabber()
		
		self.view.backgroundColorThemed = Palette.shared.black.withAlphaComponent(0.2)

		Notification.onReceive(.primeTravellerWebViewMustReload) { [weak self] _ in
			self?.fetchLocationAndLoadWebContent(force: true)
		}

		self.cacheSplashWebView.isHidden = false
		self.loadSplashThenRefreshActualWebContent()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.alertErrorIfNeeded()
		self.loadSplashThenRefreshActualWebContent()
	}

	private var loadingIndicator: UIView?

	func loadSplashThenRefreshActualWebContent() {
		if self.hasSomeContentToShow {
			return
		}

		self.loadCachedContent()

		self.showLoadingIndicatorIfNeeded()
		self.loadWebContent()
	}

	private func loadCachedContent() {
		if !webLink.isEmpty { return }

		self.cacheDebugLabel.text = "\(self.cacheDebugLabel.text ?? "")\nCACHE LOADING!"

		let success = self.cacheSplashWebView.loadWebArchive("PrimeTravellerCache")
		self.cachedContentIsLoadedIntoSplash = success

		self.cacheDebugLabel.text = "CACHE LOADED OK?: \(success)"
	}

	func loadWebContent() {
		self.fetchLocationAndLoadWebContent(force: self.shouldForceNextReload)
	}

	private func fetchLocationAndLoadWebContent(force: Bool = false) {
		let locationStatus = LocationService.shared.latestAuthorizationStatus

		guard locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse else {
			self.loadWebContentInternal()
			return
		}

		LocationService.shared.fetchLocation { [weak self] result in
			guard let self = self else { return false }

			var shouldRequestMoreLocations = false

			var locationQuery: String? = nil
			var newLocation: CLLocationCoordinate2D?

			switch result {
				case .success(let location):
					newLocation = location
				case .error(let error):
					DebugUtils.shared.alert(error.localizedDescription)
					let isOnBackground = self.view.window == nil
					shouldRequestMoreLocations = isOnBackground
			}

			let shouldOptimizeRedundantRequests = !force && self.timesContentLoaded > 0

			if shouldOptimizeRedundantRequests {
				if newLocation == self.latestLocation {
					DebugUtils.shared.log(sender: self, "PRIME TRAVELLER REFUSES TO LOAD CONTENT, REASON: self.timesContentLoaded > 0, newLocation == self.latestLocation")
					return shouldRequestMoreLocations
				}

				if let oldLocation = self.latestLocation, let newLocation = newLocation {
					if oldLocation.location.distance(from: newLocation.location) < 50 {
						DebugUtils.shared.log(sender: self, "PRIME TRAVELLER REFUSES TO LOAD CONTENT, REASON: LOCATION DIFFERENCE < 50m")
						return false
					}
				}
			}

			self.latestLocation = newLocation

			if let location = newLocation {
				locationQuery = "&latitude=\(location.latitude)&longitude=\(location.longitude)"
			}

			self.loadWebContentInternal(locationQuery: locationQuery)

			return shouldRequestMoreLocations
		}
	}

	private func loadWebContentInternal(locationQuery: String? = nil, completion: (() -> Void)? = nil) {
        var urlString = webLink.isEmpty ? Config.travellerEndpoint : self.webLink
		let hasQuery = urlString.contains("?")
		let separator = hasQuery ? "&" : "?"
        urlString.append("\(separator)\(self.utm)&env=webview&prefix=\(Config.appUrlSchemePrefix)&mobVersion=\(Config.primeTravellerAppVersion)")

		if let token = LocalAuthService.shared.token?.accessToken {
			urlString.append("&user_token=\(token)")
		}

		if let locationQuery = locationQuery {
			urlString.append(locationQuery)
		}

		let debugStatus = UserDefaults[bool: "ptDebugEnabled"] ? "enabled" : "disabled"
		urlString.append("&debugConsole=\(debugStatus)")

		guard let url = URL(string: urlString) else {
			return
		}

		var request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30.0)
		request.httpShouldHandleCookies = true

		let storage = HTTPCookieStorage.shared
		storage.cookieAcceptPolicy = .always
		request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: storage.cookies ?? [])


		if self.webView.isLoading {
			DebugUtils.shared.log(sender: self, "PRIME TRAVELLER SKIP REQUEST, SAME AS CURRENTLY LOADING \(url.absoluteString)")
			return
		}

		DebugUtils.shared.log(sender: self, "PRIME TRAVELLER WILL LOAD URL \(url.absoluteString)")

		onMain {
			self.cacheSplashWebView.isHidden = !self.cachedContentIsLoadedIntoSplash
			self.webView.stopLoading()
			self.cacheDebugLabel.text = "\(self.cacheDebugLabel.text ?? "")\nWEB LOADING!"

			if !self.hasSomeContentToShow {
				self.showLoadingIndicatorIfNeeded()
			}

			self.webView.load(request)
			completion?()
		}
	}

	private func placeWebView() {
		self.webView.backgroundColorThemed = Palette.shared.gray5
        self.webView.allowsBackForwardNavigationGestures = true
		self.webView.navigationDelegate = self
		self.webView.scrollView.delegate = self
		
		self.view.addSubview(self.webView)
		self.webView.make(.edges, .equalToSuperview)
	}

	private func placeGrabber() {
		self.view.addSubview(self.grabberView)
		self.grabberView.snp.makeConstraints { make in
			make.top.equalToSuperview().offset(5)
			make.centerX.equalToSuperview()
			make.width.equalTo(35)
			make.height.equalTo(3)
		}
	}

	private let cacheDebugLabel = UILabel()

	private func placeSplash() {
		self.view.addSubview(self.cacheSplashWebView)
		self.cacheSplashWebView.make(.edges, .equalToSuperview)
		self.cacheSplashWebView.toFront()

		if UserDefaults[bool: "PTCacheDebugEnabled"] {
			self.cacheDebugLabel.textColor = .red
			self.cacheDebugLabel.numberOfLines = 0
			self.cacheDebugLabel.lineBreakMode = .byWordWrapping
			self.cacheDebugLabel.textAlignment = .center
			self.cacheDebugLabel.font = .boldSystemFont(ofSize: 20)
			self.cacheDebugLabel.text = ""

			self.cacheSplashWebView.layer.borderWidth = 10
			self.cacheSplashWebView.layer.borderColor = UIColor.red.cgColor
			self.cacheSplashWebView.addSubview(self.cacheDebugLabel)
			self.cacheDebugLabel.make(.edges, .equalToSuperview, [100, 20, -50, -20])
		}

		self.cacheSplashWebView.isHidden = false
	}
}

extension PrimeTravellerWebViewController: WKNavigationDelegate {
	func webView(
		_ webView: WKWebView,
		decidePolicyFor navigationAction: WKNavigationAction,
		decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
	) {
		let url = navigationAction.request.url
		let scheme = url?.scheme

		DebugUtils.shared.log(sender: self, "PRIME TRAVELLER WILL DECIDE POLICY FOR URL: \(url?.absoluteString ?? "")")

		guard let url, scheme == Config.appUrlSchemePrefix else {
			decisionHandler(.allow)
			return
		}

		self.handleDeeplink(url, decisionHandler: decisionHandler)
	}

	private func handleDeeplink(_ url: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		DebugUtils.shared.log(sender: self, "PRIME TRAVELLER WILL HANDLE DEEPLINK: \(url.absoluteString)")

		guard self.dismissesOnDeeplink else {
			self.dismissesOnDeeplink = true
			self.shouldForceNextReload = true

			UIApplication.shared.open(url, options: [:], completionHandler: nil)
			decisionHandler(.cancel)
			return
		}

		self.dismiss(animated: true) {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		}

		decisionHandler(.cancel)
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		DebugUtils.shared.log(sender: self, "PRIME TRAVELLER DID LOAD CONTENT: \(webView.url?.absoluteString ?? "")")

		self.cacheDebugLabel.text = "\(self.cacheDebugLabel.text ?? "")\nSUCCESS LOADING!"

		if NetworkMonitor.shared.isConnected {
			if self.timesContentLoaded == 0 {
				webView.saveWebArchive("PrimeTravellerCache")
			}
		}

		self.timesContentLoaded += 1
		self.mayShowError = false

		self.dismissSplash()
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		DebugUtils.shared.log(sender: self, "PRIME TRAVELLER FAILED LOADING CONTENT: \(webView.url?.absoluteString ?? "")\n\(error)")

		self.cacheDebugLabel.text = "\(self.cacheDebugLabel.text ?? "")\nFAIL LOADING!"

		if self.cachedContentIsLoadedIntoSplash, self.timesContentLoaded == 0 {
			self.webView.loadWebArchive("PrimeTravellerCache")
		}

		self.mayShowError = self.timesContentLoaded == 0 && self.view.window != nil
		self.alertErrorIfNeeded()

		self.dismissSplash()
	}
}

extension PrimeTravellerWebViewController: UIScrollViewDelegate {
	func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
		scrollView.minimumZoomScale = 1
		scrollView.maximumZoomScale = 1
	}
}

extension PrimeTravellerWebViewController {
	private func showLoadingIndicatorIfNeeded() {
		if self.hasSomeContentToShow {
			return
		}

		if self.loadingIndicator == nil {
			self.loadingIndicator = self.showLoadingIndicator()
		}
	}

	private func dismissSplash() {
		delay(UserDefaults[int: "travellerSplashTimeout"]) {
			self.cacheSplashWebView.isHidden = true
			self.hideLoadingIndicator()

			if self.loadingIndicator?.superview?.tag == HUD.tag {
				self.loadingIndicator?.superview?.removeFromSuperview()
			} else {
				self.loadingIndicator?.removeFromSuperview()
			}

			self.loadingIndicator = nil
		}
	}

	private var hasSomeContentToShow: Bool {
		self.cachedContentIsLoadedIntoSplash || self.timesContentLoaded > 0
	}

	private func alertErrorIfNeeded() {
		guard self.mayShowError else {
			return
		}

		if self.view.window == nil || self.hasSomeContentToShow {
			return
		}

		DebugUtils.shared.log(sender: self, "PRIME TRAVELLER WILL SHOW STANDARD form.server.error ERROR")

		AlertPresenter.alert(
			message: "form.server.error".localized,
			actionTitle: "Ок".localized,
			onAction: { [weak self] in
				self?.dismiss(animated: true)
			})
	}
}
