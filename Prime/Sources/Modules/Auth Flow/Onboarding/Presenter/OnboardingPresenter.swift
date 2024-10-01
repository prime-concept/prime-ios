import Foundation

protocol OnboardingPresenterProtocol {
    func didLoad()
    func requestPermissionForNotifications()
    func requestPermissionForLocation()
    func didFinish()
}

final class OnboardingPresenter: OnboardingPresenterProtocol {
    weak var controller: OnboardingViewControllerProtocol?
    private let onboardingService: OnboardingServiceProtocol
    private let completion: () -> Void

    init(onboardingService: OnboardingServiceProtocol, completion: @escaping () -> Void) {
        self.onboardingService = onboardingService
        self.completion = completion
    }

    func didLoad() {
        let pages = self.onboardingService.getPageViewModels()
        self.controller?.setupPageViewControllers(with: pages)
    }

    func requestPermissionForNotifications() {
        self.onboardingService.requestPermissionForNotifications()
    }

    func requestPermissionForLocation() {
        self.onboardingService.requestPermissionForLocation()
    }

    func didFinish() {
        self.completion()
    }
}
