import UIKit
import SnapKit

protocol OnboardingViewControllerProtocol: AnyObject {
    func setupPageViewControllers(with pages: [OnboardingPageViewModel])
}

final class OnboardingViewController: UIViewController {
    private lazy var onboardingView = self.view as? OnboardingView
    private let presenter: OnboardingPresenterProtocol

    private let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: nil
    )
    private var pageItems: [OnboardingPageViewModel] = []

    init(presenter: OnboardingPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = OnboardingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter.didLoad()
    }

    // MARK: - Page view controller manipulation methods

    private func pageViewControllerFor(pageIndex: Int) -> OnboardingPageViewController? {
        let pageViewController = OnboardingPageViewController(pageIndex: pageIndex)
        guard pageIndex >= 0,
              pageIndex < self.pageItems.count else {
            return nil
        }
        pageViewController.configure(with: self.pageItems[pageIndex])
        return pageViewController
    }

    private func advanceToPageWithIndex(_ pageIndex: Int) {
        guard let nextPage = self.pageViewControllerFor(pageIndex: pageIndex) else {
            return
        }
        self.onboardingView?.configure(with: self.pageItems[pageIndex])
        self.setupOnboardingView(with: pageIndex)
        if pageIndex == 2 {
            self.presenter.requestPermissionForLocation()
        }
        self.pageViewController.setViewControllers(
            [nextPage],
            direction: .forward,
            animated: true
        )
    }

    // MARK: - Helpers

    private func setupOnboardingView(with pageIndex: Int) {
        self.onboardingView?.onClose = { [weak self] in
            self?.dismiss(animated: false) {
                self?.presenter.didFinish()
            }
        }
        self.onboardingView?.onNextButtonTap = { [weak self] in
            guard let self = self else {
                return
            }
            if pageIndex == self.pageItems.count - 1 {
                self.dismiss(animated: false) {
                    self.presenter.didFinish()
                }
            } else {
                self.advanceToPageWithIndex(pageIndex + 1)
            }
        }
    }
}

extension OnboardingViewController: OnboardingViewControllerProtocol {
    func setupPageViewControllers(with pages: [OnboardingPageViewModel]) {
        self.pageItems = pages
        self.setupOnboardingView(with: 0)
        self.onboardingView?.configure(with: self.pageItems[0])
        self.presenter.requestPermissionForNotifications()

        guard let firstPage = pageViewControllerFor(pageIndex: 0) else {
            return
        }
        self.pageViewController.setViewControllers(
            [firstPage],
            direction: .forward,
            animated: false
        )
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self

        self.addChild(self.pageViewController)
        self.onboardingView?.addPageToContainer(view: self.pageViewController.view)
        self.pageViewController.didMove(toParent: self)
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let pageViewController = pageViewController.viewControllers?.first as? OnboardingPageViewController else {
            return
        }
        let currentPageIndex = pageViewController.pageIndex
        if currentPageIndex == 2 {
            self.presenter.requestPermissionForLocation()
        }
        self.setupOnboardingView(with: currentPageIndex)
        self.onboardingView?.configure(with: self.pageItems[currentPageIndex])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let pageViewController = viewController as? OnboardingPageViewController,
              pageViewController.pageIndex != 0 else {
            return nil
        }
        let pageIndex = pageViewController.pageIndex
        return self.pageViewControllerFor(pageIndex: pageIndex - 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let pageViewController = viewController as? OnboardingPageViewController else {
            return nil
        }
        let pageIndex = pageViewController.pageIndex
        return self.pageViewControllerFor(pageIndex: pageIndex + 1)
    }
}
