import SnapKit
import UIKit

final class ContainerStackView: UIView {
    enum Axis {
        case vertical, horizontal
    }

    var axis: Axis = .vertical {
        didSet {
            let views = self.views
            self.resetViews()
            views.forEach { self.addView(view: $0) }
        }
    }
    var spacing: Int = 15

    private(set) var views: [UIView] = []
    private var nextConstraint: Constraint?

    override var intrinsicContentSize: CGSize {
        let extraSpacing: CGFloat = self.views.isEmpty ? 0 : CGFloat(self.spacing)
        let viewsIntrinsicHeight = self.views.reduce(
            -extraSpacing, { result, view in
                result + view.intrinsicContentSize.height + CGFloat(self.spacing)
            }
        )

        return CGSize(width: UIView.noIntrinsicMetric, height: viewsIntrinsicHeight)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetViews() {
        for view in self.views {
            view.removeFromSuperview()
        }
        self.views = []
        self.nextConstraint = nil
    }

    func addView(view: UIView) {
        self.nextConstraint?.deactivate()
        self.addSubview(view)
        view.snp.makeConstraints { make in
            switch self.axis {
            case .vertical:
                make.leading.trailing.equalToSuperview()
                if let previousView = self.views.last {
                    make.top.equalTo(previousView.snp.bottom).offset(self.spacing)
                } else {
                    make.top.equalToSuperview()
                }
                self.nextConstraint = make.bottom.equalToSuperview().constraint
            case .horizontal:
                make.top.bottom.equalToSuperview()
                if let previousView = self.views.last {
                    make.leading.equalTo(previousView.snp.trailing).offset(self.spacing)
                } else {
                    make.leading.equalToSuperview()
                }
                self.nextConstraint = make.trailing.equalToSuperview().constraint
            }
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()

        self.views += [view]
    }
}
