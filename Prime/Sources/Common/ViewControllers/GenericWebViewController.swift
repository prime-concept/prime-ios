import UIKit
import WebKit

class GenericWebViewController: UIViewController, UIScrollViewDelegate {
	private let url: URL
	private let showLoader: Bool
	private var dismissesOnDeeplink = true
	
	private(set) lazy var webView = WKWebView(
		frame: UIScreen.main.bounds,
		configuration: with(WKWebViewConfiguration()){ config in
			config.suppressesIncrementalRendering  = true
	})

	init(url: URL, dismissesOnDeeplink: Bool = false, showLoader: Bool = false) {
		self.url = url
		self.showLoader = showLoader
		self.dismissesOnDeeplink = dismissesOnDeeplink
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		self.view = self.webView

		self.webView.backgroundColorThemed = Palette.shared.gray5
		self.webView.allowsBackForwardNavigationGestures = true
		self.webView.navigationDelegate = self
		self.webView.scrollView.delegate = self
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.webView.load(URLRequest(url: self.url))
		delay(0.3) {
			if self.showLoader {
				self.showLoadingIndicator()
			}
		}
	}
}

extension GenericWebViewController: WKNavigationDelegate {
	func webView(
		_ webView: WKWebView,
		decidePolicyFor navigationAction: WKNavigationAction,
		decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
	) {
		let url = navigationAction.request.url
		let scheme = url?.scheme

		DebugUtils.shared.log(sender: self, "GenericWebViewController WILL DECIDE POLICY FOR URL: \(url?.absoluteString ?? "")")

		guard let url, scheme == Config.appUrlSchemePrefix else {
			decisionHandler(.allow)
			return
		}

		self.handleDeeplink(url, decisionHandler: decisionHandler)
	}

	private func handleDeeplink(_ url: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		DebugUtils.shared.log(sender: self, "GenericWebViewController WILL HANDLE DEEPLINK: \(url.absoluteString)")

		guard self.dismissesOnDeeplink else {
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
		if self.showLoader {
			self.hideLoadingIndicator()
		}
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		if self.showLoader {
			self.hideLoadingIndicator()
		}
	}
}
