import ChatSDK
import UIKit

final class HomeViewController: UIViewController {
    
    private lazy var homeView = self.view as? HomeView
    private var expandAnimator: HomeCalendarExpandAnimator?
    
    var shouldShowSafeAreaView: Bool { true }
    var presenter: HomePresenterProtocol?
    var router: (any HomeRouterProtocol)?
    
    private var tasksLoaderIsBeingShown = false
	private var commonLoaderIsBeingShown = false

    override func loadView() {
        self.view = HomeView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.didLoad()
        self.homeView?.onTapProfile = { [weak self] in
            self?.router?.openProfile()
        }
        self.homeView?.openDetailCalendar = { [weak self] date in self?.router?.openDetailCalendar(date: date) }
        self.homeView?.onRefreshList = { [weak self] in
            self?.presenter?.didPullToRefresh()
        }
        self.homeView?.onOpenGeneralChat = { [weak self] in
            self?.router?.openChat(message: nil) {}
        }
        self.homeView?.onOpenPayFilter = { [weak self] in
            self?.router?.openPayTasks()
        }
        self.homeView?.onOpenCompletedTasks = { [weak self] in
            self?.router?.openCompletedTasks()
        }
        self.homeView?.onOrderTap = { [weak self] orderID in
            self?.router?.openPayment(orderID: orderID)
        }
        self.homeView?.onEmptyListTap = { [weak self] in
            self?.router?.openRequestCreation(message: nil)
        }
        self.homeView?.onPromoCategoryTap = { [weak self] categoryID in
            self?.router?.openPromoCategory(id: categoryID)
        }
        
        // Чтобы скрыть "Back" на последующих контроллерах в стеке
        self.navigationItem.backButtonTitle = " "
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presenter?.didAppear()
    }
}

// MARK: - HomeViewControllerProtocol

extension HomeViewController: HomeViewControllerProtocol {
    
    func set(viewModel: HomeViewModel) {
        self.homeView?.update(viewModel: viewModel)
    }

	func showTasksLoader() {
		self.showTasksLoader(offset: CGPoint(x: 0, y: 66), needsPad: false)
	}
    
	func showTasksLoader(offset: CGPoint, needsPad: Bool) {
		if self.tasksLoaderIsBeingShown {
			return
		}

		self.homeView?.requestListView.alpha = 0.4
		self.homeView?.requestListView.showLoadingIndicator(offset: offset)

		self.tasksLoaderIsBeingShown = true
	}

	func hideTasksLoader() {
		self.homeView?.requestListView.alpha = 1.0
		self.homeView?.requestListView.hideLoadingIndicator()

		self.tasksLoaderIsBeingShown = false
	}

	func showCommonLoader() {
		self.showCommonLoader(hideAfter: nil)
	}

	func showCommonLoader(hideAfter timeout: TimeInterval?) {
		if self.commonLoaderIsBeingShown {
			return
		}
		
		self.commonLoaderIsBeingShown = true

		weak var loader = self.homeView?.showLoadingIndicator(needsPad: true, offset: .zero)
		guard let timeout else { return }

		delay(timeout) {
			if let loader {
				self.hideCommonLoader()
			}
		}
	}

	func hideCommonLoader() {
		if self.commonLoaderIsBeingShown {
			self.homeView?.hideLoadingIndicator()
			self.commonLoaderIsBeingShown = false
		}
	}
}

extension HomeViewController: HomeCalendarExpandAnimator.SourceController {
    var containerViewBounds: CGRect {
        guard let window = self.view.window, let view = self.homeView?.containerView else {
            return .zero
        }

        self.homeView?.setNeedsLayout()
        self.homeView?.layoutIfNeeded()

        return view.convert(view.bounds, to: window)
    }

    var containerView: UIView {
        self.homeView?.containerView ?? UIView()
    }

    var containerViewContentSnapshotBounds: CGRect? {
        guard let window = self.view.window, let view = self.homeView?.containerContentView else {
            return .zero
        }

        self.homeView?.setNeedsLayout()
        self.homeView?.layoutIfNeeded()

        return view.convert(view.bounds, to: window)
    }

    func makeContainerViewContentSnapshot() -> UIView? {
        self.homeView?.containerContentView?.snapshotView(afterScreenUpdates: true)
    }

    func cloneContainerView() -> UIView {
        ShadowContainerView()
    }
}

extension HomeViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let toController = presented as? HomeCalendarExpandAnimator.DestinationController else {
            return nil
        }

        self.expandAnimator = HomeCalendarExpandAnimator(type: .present, from: self, to: toController)

        return self.expandAnimator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let toController = dismissed as? HomeCalendarExpandAnimator.DestinationController else {
            return nil
        }

        self.expandAnimator = HomeCalendarExpandAnimator(type: .dismiss, from: self, to: toController)

        return self.expandAnimator
    }
}
