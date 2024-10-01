import UIKit

final class FeedbackAssembly {
	private let feedback: ActiveFeedback
    private let alreadyRatedStars: Int?

	public init(feedback: ActiveFeedback, alreadyRatedStars: Int? = nil) {
		self.feedback = feedback
        self.alreadyRatedStars = alreadyRatedStars
	}

	public func makeModule() -> UIViewController {
		let presenter = FeedbackPresenter(feedback: self.feedback)
        let viewController = FeedbackViewController(presenter: presenter, alreadyRatedStars: self.alreadyRatedStars)
		presenter.viewController = viewController

		return viewController
	}
}
