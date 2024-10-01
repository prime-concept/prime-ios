import FloatingPanel
import UIKit

enum FloatingControllerContext {
    case authCountryCodes
    case itemSelection

    fileprivate var initialPosition: FloatingPanelPosition {
        switch self {
        case .authCountryCodes:
            return .full
        case .itemSelection:
            return .half
        }
    }

    var isFullPositionSupported: Bool {
        switch self {
        case .authCountryCodes:
            return true
        case .itemSelection:
            return false
        }
    }

    var isHalfPositionSupported: Bool {
        switch self {
        case .authCountryCodes:
            return false
        case .itemSelection:
            return true
        }
    }

    var insetForFullPosition: CGFloat {
        switch self {
        case .authCountryCodes:
            return 197
        default:
            return 0
        }
    }

    var insetForHalfPosition: CGFloat {
        switch self {
        case .itemSelection:
            return 568
        default:
            fatalError("Unsupported context")
        }
    }
}

final class FloatingControllerPresentationManager {
    private lazy var floatingController: FloatingPanelController = {
        let controller = FloatingPanelController(delegate: self)
        controller.surfaceView.cornerRadius = 20
        controller.surfaceView.shadowHidden = true
        controller.isRemovalInteractionEnabled = true

        controller.surfaceView.grabberHandle.isHidden = true

        let grabberView = UIView()
        grabberView.isUserInteractionEnabled = false
        grabberView.backgroundColorThemed = Palette.shared.darkLightColor
        controller.surfaceView.addSubview(grabberView)
        grabberView.clipsToBounds = true
        grabberView.layer.cornerRadius = 2
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        grabberView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 36, height: 4))
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }

        return controller
    }()

    var contentViewController: UIViewController?
    private let sourceViewController: UIViewController

    fileprivate var currentPosition: FloatingPanelPosition = .half

    var context: FloatingControllerContext {
        didSet {
            UIView.animate(withDuration: 0.25) {
                self.floatingController.updateLayout()
            }
        }
    }

    var contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior = .always {
        didSet {
            self.floatingController.contentInsetAdjustmentBehavior = self.contentInsetAdjustmentBehavior
        }
    }

    init(
        context: FloatingControllerContext,
        contentViewController: UIViewController? = nil,
        sourceViewController: UIViewController
    ) {
        self.context = context
        self.contentViewController = contentViewController
        self.sourceViewController = sourceViewController
    }

    // MARK: - Public API

    func track(scrollView: UIScrollView?) {
        self.floatingController.track(scrollView: scrollView)
    }

    func move(to position: FloatingPanelPosition) {
        guard position != self.currentPosition else {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.floatingController.move(to: position, animated: false)
        }
    }

    func present() {
        precondition(self.floatingController.parent == nil)

        guard self.floatingController.presentingViewController == nil else {
            DebugUtils.shared.alert(sender: self, "floating presentation manager: presenting controller is not null")
            return
        }

        self.floatingController.set(contentViewController: self.contentViewController)
        self.sourceViewController.present(self.floatingController, animated: true, completion: nil)
    }
}

extension FloatingControllerPresentationManager: FloatingPanelControllerDelegate {
    func floatingPanel(
        _ viewController: FloatingPanelController,
        layoutFor newCollection: UITraitCollection
    ) -> FloatingPanelLayout? {
        CustomFloatingPanelLayout(manager: self)
    }
}

private class CustomFloatingPanelLayout: FloatingPanelLayout {
    private weak var manager: FloatingControllerPresentationManager?

    init(manager: FloatingControllerPresentationManager) {
        self.manager = manager
    }

    var initialPosition: FloatingPanelPosition {
        guard let manager = self.manager else {
            fatalError("Presentation manager is detached")
        }

        return manager.context.initialPosition
    }

    var supportedPositions: Set<FloatingPanelPosition> {
        guard let manager = self.manager else {
            fatalError("Presentation manager is detached")
        }

        var positions: [FloatingPanelPosition] = manager.context.isHalfPositionSupported
            ? [.half]
            : []

        if manager.context.isFullPositionSupported {
            positions += [.full]
        }

        return .init(positions)
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        guard let manager = self.manager else {
            fatalError("Presentation manager is detached")
        }

        switch position {
        case .full:
             return manager.context.insetForFullPosition
        case .half:
            return manager.context.insetForHalfPosition
        default:
            return nil
        }
    }

    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        0.7
    }
}
