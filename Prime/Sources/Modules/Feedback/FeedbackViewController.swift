import UIKit

protocol FeedbackViewProtocol: UIViewController {
	func setup(with viewModel: FeedbackViewModel)
}

final class FeedbackViewController: UIViewController, FeedbackViewProtocol {
	private let presenter: FeedbackPresenter
    private let feedbackView: FeedbackView
    
    @ThreadSafe private var autodismissTimer: Timer?

	init(presenter: FeedbackPresenter, alreadyRatedStars: Int?) {
		self.presenter = presenter
        
        feedbackView = FeedbackView(alreadyRatedStars: alreadyRatedStars)
		super.init(nibName: nil, bundle: nil)
        feedbackView.delegate = self
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        
		self.placeSubviews()
		self.presenter.didLoad()
	}

	func setup(with viewModel: FeedbackViewModel) {
		self.feedbackView.setup(with: viewModel)
	}

	private func placeSubviews() {
		self.view.addSubview(self.feedbackView)
		self.feedbackView.make(.edges, .equalToSuperview, [18, 0, 0, 0])
		self.view.backgroundColorThemed = self.feedbackView.backgroundColorThemed

		let grabber = GrabberView()
		self.view.addSubview(grabber)
		grabber.make([.top, .centerX], .equalToSuperview, [10, 0])
	}
}

// MARK: - FeedbackViewDelegate

extension FeedbackViewController: FeedbackViewDelegate {
    
    func feedbackViewDidPresentSuccessView(_ feedbackView: FeedbackView) {
        autodismissTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.autodismissOnSuccessDuration,
            repeats: false
        ) { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }
    
}

// MARK: - Constants

fileprivate enum Constants {
    static let autodismissOnSuccessDuration: TimeInterval = 2
}
