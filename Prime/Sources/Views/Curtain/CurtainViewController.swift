import UIKit

class CurtainViewController: UIViewController {
	let curtainView: CurtainView
	var curtainViewTopConstraint: NSLayoutConstraint?

    private lazy var backgroundView = UIView { view in
        view.addTapHandler(feedback: .none) { [weak self] in
            self?.curtainView.scrollTo(ratio: 0)
        }
    }

	init(
		with contentView: UIView,
		backgroundView: (() -> UIView)? = nil,
		backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7),
		contentInset: UIEdgeInsets = .init(top: 30, left: 0, bottom: 0, right: 0),
		initialRatio: CGFloat = 1.0
	) {
		self.curtainView = CurtainView(
			content: contentView,
			contentInset: contentInset,
			initialRatio: initialRatio
		)
		
		self.curtainView.magneticRatios = [0]

		super.init(nibName: nil, bundle: nil)

		self.modalPresentationStyle = .overFullScreen
		self.backgroundView = backgroundView?() ?? UIView()
		self.backgroundView.backgroundColor = backgroundColor
		self.backgroundView.alpha = 0
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.addSubview(self.backgroundView)
		self.view.sendSubviewToBack(self.backgroundView)
		self.backgroundView.make(.edges, .equalToSuperview)

		self.view.addSubview(self.curtainView)
		self.curtainViewTopConstraint = self.curtainView.make(.edges, .equalToSuperview)[0]
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		UIView.animate(withDuration: 0.3) {
			self.backgroundView.alpha = 1
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.curtainView.animateAlongsideMagneticScroll ??= { [weak self] from, to, _ in
			if to == 0 {
				self?.backgroundView.alpha = 0
			}
		}

		self.curtainView.didAnimateMagneticScroll ??= { [weak self] from, to in
			if to == 0 {
				self?.dismiss(animated: false)
			}
		}
	}

	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		guard self.presentedViewController == nil else {
			super.dismiss(animated: flag, completion: completion)
			return
		}

		if self.curtainView.currentRatio <= 0 {
			super.dismiss(animated: flag, completion: completion)
			return
		}

		self.curtainView.scrollTo(ratio: 0, animated: flag)
		delay(self.curtainView.animationDuration) {
			completion?()
		}
	}
}
