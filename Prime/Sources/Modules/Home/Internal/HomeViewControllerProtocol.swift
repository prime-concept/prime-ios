import UIKit

protocol HomeViewControllerProtocol: ModalRouterSourceProtocol, UIViewControllerTransitioningDelegate {
    func set(viewModel: HomeViewModel)

    func showTasksLoader()
    func showTasksLoader(offset: CGPoint, needsPad: Bool)
    func hideTasksLoader()

    func showCommonLoader()
    func showCommonLoader(hideAfter timeout: TimeInterval?)
    func hideCommonLoader()
}
