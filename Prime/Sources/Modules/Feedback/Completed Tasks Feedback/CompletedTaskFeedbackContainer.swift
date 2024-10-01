import UIKit
import SnapKit

final class CompletedTaskFeedbackContainer: UIView {
    var didTapOnStars: ((Int) -> Void)?
    var didCloseContainer: (() -> Void)?
    
	private lazy var feedbackBottomSheetView = with(CompletedTaskFeedbackView()) {
		$0.didTapOnStars = { [weak self] rate in
			self?.didTapOnStars?(rate)
		}
		$0.isUserInteractionEnabled = true
	}
    
	private(set) lazy var curtainView = with(
		CurtainView(
			content: self.feedbackBottomSheetView,
			contentInset: .tlbr(0, 0, -54, 0)
		)
	) { curtainView in

		curtainView.magneticRatios = [0]
		curtainView.animatedMoveToWindow = false
        curtainView.hidesOnPanToBottom = true
        curtainView.setCurtainBackgroundThemedColor = Palette.shared.gray5

		curtainView.animateAlongsideMagneticScroll = { [weak self] from, to, duration in
			if to == 0 {
				self?.backgroundView.alpha = 0
			}
		}

		curtainView.didAnimateMagneticScroll = { [weak self] from, to in
			if to == 0 {
				self?.didCloseContainer?()
			}
		}
    }
    
	private lazy var backgroundView = UIView { view in
		view.backgroundColor = .black.withAlphaComponent(0.7)
	}

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    func setupUI() {
        self.backgroundColor = .clear
        self.addSubview(self.backgroundView)
        self.backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

		backgroundView.addTapHandler(feedback: .none) { [weak self] in
			self?.curtainView.scrollTo(ratio: 0)
		}
        
        self.addSubview(self.curtainView)
        self.curtainView.make(.edges, .equalToSuperview)
    }

	func closeBottomSheet() {
		self.curtainView.scrollTo(ratio: 0)
	}
}
