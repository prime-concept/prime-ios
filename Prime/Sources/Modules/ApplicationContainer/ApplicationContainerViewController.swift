import UIKit

final class ApplicationContainerViewController: UIViewController {
	private var hiddenWindow: UIWindow?
	private lazy var blockingWindow = PrimeWindow.blocking

    private let presenter: ApplicationContainerPresenterProtocol

    private var currentChild: UIViewController?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.currentChild?.preferredStatusBarStyle ?? .default
    }

    init(presenter: ApplicationContainerPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter.didLoad()

		self.navigationItem.backButtonTitle = " "
    }

	func presentBlocking(
		_ viewController: UIViewController,
		animated: Bool = false,
		completion: (() -> Void)? = nil)
	{
		self.hiddenWindow = UIWindow.keyWindow

		self.blockingWindow.alpha = 0

		self.blockingWindow.rootViewController = viewController

		self.blockingWindow.frame = UIScreen.main.bounds

		self.blockingWindow.setNeedsLayout()
		
		UIView.performWithoutAnimation {
			self.blockingWindow.layoutIfNeeded()
			self.blockingWindow.makeKeyAndVisible()
		}

		UIView.animate(withDuration: animated ? 0.25 : 0, delay: animated ? 0.1 : 0) {
			self.blockingWindow.alpha = 1
		}
	}

	func dismissBlockingViewController(_ completion: (() -> Void)? = nil) {
		guard self.blockingWindow.isKeyWindow, self.blockingWindow.alpha != 0 else {
			completion?()
			return
		}
		
		UIView.animate(withDuration: 0.25, animations: {
			self.blockingWindow.alpha = 0
		}) { _ in
			self.hiddenWindow?.makeKeyAndVisible()
			self.blockingWindow.rootViewController = nil
			completion?()
		}
	}

	func displayChild(viewController: UIViewController, completion: (() -> Void)? = nil) {
        self.currentChild?.view.removeFromSuperview()
        self.currentChild?.removeFromParent()

        self.addChild(viewController)
        self.view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        viewController.view.alpha = 0

        UIView.animate(
            withDuration: 0.5,
            delay: 0.1,
            options: .transitionFlipFromLeft,
            animations: {
                viewController.view.alpha = 1
            },
            completion: { _ in
                viewController.didMove(toParent: self)
				completion?()
            }
        )

        self.currentChild = viewController
        self.setNeedsStatusBarAppearanceUpdate()
    }

	func dismissChild(viewController: UIViewController) {
		guard viewController == self.currentChild else {
			return
		}
		self.currentChild?.willMove(toParent: nil)
		self.currentChild?.view.removeFromSuperview()
		self.currentChild?.removeFromParent()
		self.currentChild?.didMove(toParent: nil)
		self.currentChild = nil
	}
}
