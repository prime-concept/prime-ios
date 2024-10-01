import UIKit

// MARK: - Protocols

// Контроллер 1, с которого делаем экспанд (Home)
protocol HomeCalendarExpandTransitionSource: UIViewController {
    // Фрейм вьюшки, которую экспандим, в координатах window
    var containerViewBounds: CGRect { get }

    // Вьюшка, которую экспандим. Нужно, чтобы уметь управлять отдельно её прозрачность
    var containerView: UIView { get }

    // Фрейм снешпота контента вьюшки, которую экспандим
    var containerViewContentSnapshotBounds: CGRect? { get }

    // Клон вьюшки-контейнера, который будем анимировать
    func cloneContainerView() -> UIView

    // Снешпот контента вьюшки, которую экспандим. Чтобы скрыть его анимировано
    func makeContainerViewContentSnapshot() -> UIView?
}

// Контроллер 2, на который делаем экспанд (DetailCalendar)
protocol HomeCalendarExpandTransitionDestination: UIViewController {
    // Фрейм вьюшки, которую коллапсим, в координатах window
    var containerViewBounds: CGRect { get }

    // Фрейм снешпота контента вьюшки, которую открываем
    var containerViewContentSnapshotBounds: CGRect? { get }

    // Клон вьюшки-контейнера, который будем анимировать
    func cloneContainerView() -> UIView

    // Снешпот контента вьюшки, которую открываем. Чтобы показать его анимировано
    func makeContainerViewContentSnapshot() -> UIView?

    // Заблюренный бекграунд, который появляется на 2
    static func makeBlurredBackgroundView() -> UIView
}

// MARK: - Animator

final class HomeCalendarExpandAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    typealias SourceController = HomeCalendarExpandTransitionSource
    typealias DestinationController = HomeCalendarExpandTransitionDestination

    private static let duration: TimeInterval = 0.4

    private let type: Type
    private let sourceController: SourceController
    private let destinationController: DestinationController

    init?(
        type: Type,
        from sourceController: SourceController,
        to destinationController: DestinationController
    ) {
        self.type = type
        self.sourceController = sourceController
        self.destinationController = destinationController
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        Self.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let transitionsContainerView = transitionContext.containerView

        let isPresenting = self.type == .present

        let srcView = self.sourceController.containerView
        guard let dstView = self.destinationController.view else {
            transitionContext.completeTransition(false)
            return
        }

        // Для srcView ставим дальше, чтобы не было миганий в контейнере
        dstView.alpha = 0.0

        transitionsContainerView.addSubview(dstView)

        let srcContainerViewRect: CGRect
        let dstContainerViewRect: CGRect

        if isPresenting {
            srcContainerViewRect = self.sourceController.containerViewBounds
            dstContainerViewRect = self.destinationController.containerViewBounds
        } else {
            srcContainerViewRect = self.destinationController.containerViewBounds
            dstContainerViewRect = self.sourceController.containerViewBounds
        }

        if srcContainerViewRect.isEmpty || dstContainerViewRect.isEmpty {
            dstView.alpha = 1.0
            transitionContext.completeTransition(true)
            return
        }

        let backgroundView = Swift.type(of: self.destinationController).makeBlurredBackgroundView()
        backgroundView.alpha = isPresenting ? 0.0 : 1.0
        backgroundView.frame = transitionsContainerView.bounds

        let currentContainerView: UIView
        if isPresenting {
            currentContainerView = self.sourceController.cloneContainerView()
        } else {
            currentContainerView = self.destinationController.cloneContainerView()
        }

        let srcContainerViewContentView = self.sourceController.makeContainerViewContentSnapshot() ?? UIView()
        let dstContainerViewContentView = self.destinationController.makeContainerViewContentSnapshot() ?? UIView()

        currentContainerView.frame = srcContainerViewRect

        srcContainerViewContentView.alpha = isPresenting ? 1.0 : 0.0
        srcContainerViewContentView.frame = self.sourceController.containerViewContentSnapshotBounds ?? .zero

        dstContainerViewContentView.alpha = isPresenting ? 0.0 : 1.0
        dstContainerViewContentView.frame = self.destinationController.containerViewContentSnapshotBounds ?? .zero

        [
            backgroundView,
            currentContainerView,
            srcContainerViewContentView,
            dstContainerViewContentView
        ].forEach { transitionsContainerView.addSubview($0) }

        let sourceViewAlpha = srcView.alpha
        srcView.alpha = 0.0

        UIView.animateKeyframes(
            withDuration: Self.duration,
            delay: 0.0,
            options: .calculationModeCubic,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                    currentContainerView.frame = dstContainerViewRect
                }

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: isPresenting ? 0.7 : 0.3) {
                    backgroundView.alpha = isPresenting ? 1.0 : 0.0
                }

                UIView.addKeyframe(withRelativeStartTime: isPresenting ? 0.0 : 0.4, relativeDuration: 0.6) {
                    srcContainerViewContentView.alpha = isPresenting ? 0.0 : 1.0
                }

                UIView.addKeyframe(withRelativeStartTime: isPresenting ? 0.4 : 0.0, relativeDuration: 0.6) {
                    dstContainerViewContentView.alpha = isPresenting ? 1.0 : 0.0
                }
            },
            completion: { _ in
                [
                    backgroundView,
                    currentContainerView,
                    srcContainerViewContentView,
                    dstContainerViewContentView
                ].forEach { $0.removeFromSuperview() }

                srcView.alpha = sourceViewAlpha
                dstView.alpha = 1.0

                transitionContext.completeTransition(true)
            }
        )
    }

    enum `Type` {
        case present
        case dismiss
    }
}
