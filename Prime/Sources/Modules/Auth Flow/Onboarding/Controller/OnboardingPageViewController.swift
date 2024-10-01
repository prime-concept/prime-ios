import UIKit

final class OnboardingPageViewController: UIViewController {
    private lazy var onboardingPageView = self.view as? OnboardingPageView
    let pageIndex: Int

    init(pageIndex: Int) {
        self.pageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = OnboardingPageView()
    }

    // MARK: - Public APIs

    func configure(with page: OnboardingPageViewModel) {
        self.onboardingPageView?.configure(with: page)
    }
}
