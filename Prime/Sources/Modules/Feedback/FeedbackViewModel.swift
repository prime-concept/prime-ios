import UIKit

struct FeedbackViewModel {
	enum State {
		case initial
		case details
		case success
	}

	var state: State

	var title: String = "feedback.please.rate2".localized

	let taskIcon: UIImage?
	let taskName: String?
	let taskDate: String?

	var worstSubscription: String = "feedback.bad".localized
	var bestSubscription: String = "feedback.excellent".localized

	var complaintsTitle: String?
	var complaintsSubtitle: String?

	var complaints: [String] = []
	var feedbackPlaceholder: String = "feedback.comment.prompt".localized

	var successTitle: String = "feedback.success.title".localized
	var successSubtitle: String = "feedback.success.subtitle".localized

	var actionButtonTitle: String = "feedback.submit".localized

	var onRatingChanged: (Int) -> Void
	// (rating: Int, complaintsIndices: [Int], feedback: String?) -> Void
	let onSubmit: (Int, [Int], String?) -> Void
	let onFinish: () -> Void
}
