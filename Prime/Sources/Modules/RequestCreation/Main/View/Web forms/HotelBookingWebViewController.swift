import UIKit
import WebKit

protocol RequestFormViewController: UIViewController {
	func sendRequest(completion: @escaping (Int?, Error?) -> Void)
	func reset()
}

final class HotelBookingWebViewController: UIViewController {
	struct BookingError: Error { }

	private var latestValidURL: URL?
	private var isContentShown = false
	private var mayLoadContent = true
	private var completionHandler: ((Int?, Error?) -> Void)? = nil

	private let snapshot = UIImageView()

	private lazy var webView = with(WKWebView(frame: UIScreen.main.bounds)) { webView in
		webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
		webView.navigationDelegate = self
		webView.scrollView.delegate = self
		webView.isOpaque = false
		webView.backgroundColorThemed = Palette.shared.clear
		webView.scrollView.backgroundColorThemed = Palette.shared.clear
		webView.alpha = 0
	}

	private lazy var backgroundImageView = with(UIImageView()) { imageView in
		imageView.contentMode = .scaleAspectFill
		imageView.image = RequestBackgroundRandomizer.image(
			named: "request_creation_hotel_background",
			range: 1...1
		)
		imageView.alpha = 0
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColorThemed = Palette.shared.gray5

		self.showLoadingIndicator()
		self.view.isUserInteractionEnabled = true

		self.placeBackground()
		self.placeWebView()
		self.placeGrabber()
		self.placeChatKeyboardDismissingView()

		if self.mayLoadContent {
			self.loadWebContent()
		}
	}

	func loadWebContent() {
		LocationService.shared.fetchLocation { [weak self] result in
			guard let self = self else {
				return false
			}

			var shouldRequestMoreLocations = false

			var locationQuery = ""
			switch result {
				case .success(let location):
					locationQuery = "&latitude=\(location.latitude)&longitude=\(location.longitude)"
				case .error(let error):
					DebugUtils.shared.alert(error.localizedDescription)
					let isOnBackground = self.view.window == nil
					shouldRequestMoreLocations = isOnBackground
			}
			let token = LocalAuthService.shared.token?.accessToken ?? ""
			self.latestValidURL = URL(string: "\(Config.travellerEndpoint)/forms/hotel/?env=webview&user_token=\(token)" + locationQuery)
			self.latestValidURL.some {
				var request = URLRequest(url: $0, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.0)
				request.httpShouldHandleCookies = true

				let storage = HTTPCookieStorage.shared
				storage.cookieAcceptPolicy = .always
				request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: storage.cookies ?? [])

				self.webView.load(request)

				self.mayLoadContent = false
			}

			return shouldRequestMoreLocations
		}
	}

	private func placeBackground() {
		self.view.addSubview(self.backgroundImageView)
		self.backgroundImageView.make(.edges, .equalToSuperview)
	}

	private func placeWebView() {
		let blankSheetView = UIView{ $0.backgroundColorThemed = Palette.shared.gray5 }
		self.view.addSubview(blankSheetView)
		blankSheetView.make(.edges(except: .top), .equalToSuperview)
		blankSheetView.make(.height, .equal, 100)

		self.view.addSubview(self.webView)
		self.webView.make(.edges, .equalToSuperview)
	}

	private func placeChatKeyboardDismissingView() {
		let view = ChatKeyboardDismissingView()
		self.view.addSubview(view)
		view.make(.edges(except: .bottom), .equalToSuperview)
		view.make(.height, .equal, 44)
	}

	private func placeGrabber() {
		let grabberView = with(UIView()) { view in
			view.backgroundColorThemed = Palette.shared.gray3
			view.layer.cornerRadius = 1.5
		}

		self.view.addSubview(grabberView)
		grabberView.snp.makeConstraints { make in
			make.top.equalToSuperview().offset(5)
			make.centerX.equalToSuperview()
			make.width.equalTo(35)
			make.height.equalTo(3)
		}
	}

	private func showContentIfNeeded() {
		if self.isContentShown {
			return
		}

		self.isContentShown = true

		self.webView.alpha = 1.0
		self.backgroundImageView.alpha = 1.0

		self.snapshot.removeFromSuperview()

		let renderer = UIGraphicsImageRenderer(size: self.webView.bounds.size)
		let image = renderer.image { _ in
			self.view.drawHierarchy(in: self.webView.frame, afterScreenUpdates: true)
		}
		self.snapshot.image = image
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard keyPath == #keyPath(WKWebView.url),
			  let newUrl = self.webView.url,
			  let latestValidURL = self.latestValidURL else {
			return
		}

		if latestValidURL.path != newUrl.path {
			self.webView.addSubview(self.snapshot)
			self.snapshot.make(.edges, .equalToSuperview)
			self.isContentShown = false

			self.webView.load(URLRequest(url: latestValidURL))
			return
		}

		self.latestValidURL = newUrl

		DebugUtils.shared.alert(sender: self, "URL loaded: \(newUrl.absoluteString)")
		self.callCompletion(with: newUrl)
	}
}

extension HotelBookingWebViewController: WKNavigationDelegate {
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		DispatchQueue.main.async {
			self.showContentIfNeeded()
		}
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		DispatchQueue.main.async {
			self.showContentIfNeeded()
		}
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
		decisionHandler(.allow)
	}
}

extension HotelBookingWebViewController: UIScrollViewDelegate {
	func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
		scrollView.minimumZoomScale = 1
		scrollView.maximumZoomScale = 1
	}
}

extension HotelBookingWebViewController: RequestFormViewController {
	public func sendRequest(completion: @escaping (Int?, Error?) -> Void) {
		self.webView.evaluateJavaScript("onRequestSend()", completionHandler: nil)
		self.completionHandler = completion
	}

	private func callCompletion(with url: URL) {
		let string = url.absoluteString
		guard let items = URLComponents(string: string)?.queryItems else {
			return
		}

		if let id = items.first(where: { $0.name == "id" })?.value {
			self.completionHandler?(Int(id), nil)
			return
		}

		if let _ = items.first(where: { $0.name == "error" }) {
			self.completionHandler?(nil, BookingError())
			return
		}
	}

	public func reset() {
		self.isContentShown = false
		self.mayLoadContent = true
		self.loadWebContent()
	}
}

class ChatKeyboardDismissingView: UIView {
	private var latestLocation: CGPoint!

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColorThemed = Palette.shared.clear
		self.isUserInteractionEnabled = true
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let location = touches.first?.location(in: self) else {
			return
		}

		self.latestLocation = location
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let location = touches.first?.location(in: self) else {
			return
		}
		if location.y > self.latestLocation.y {
			Notification.post(.messageInputShouldHideKeyboard)
		}
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let location = touches.first?.location(in: self) else {
			return
		}

		if location.y > self.latestLocation.y {
			Notification.post(.messageInputShouldHideKeyboard)
		}
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let location = touches.first?.location(in: self) else {
			return
		}

		if location.y > self.latestLocation.y {
			Notification.post(.messageInputShouldHideKeyboard)
		}
	}
}
