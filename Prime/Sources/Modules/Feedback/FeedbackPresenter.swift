import UIKit

extension Notification.Name {
	static let didSubmitFeedback = Notification.Name("didSubmitFeedback")
}

protocol FeedbackPresenterProtocol {
	func didLoad()
}

final class FeedbackPresenter: FeedbackPresenterProtocol {
	private let feedback: ActiveFeedback
	weak var viewController: (any FeedbackViewProtocol)?
	var feedbackValues: ActiveFeedback.Value?

	public init(feedback: ActiveFeedback) {
		self.feedback = feedback
	}

	func didLoad() {
		let viewModel = self.viewModelForCurrentState
		self.viewController?.setup(with: viewModel)
	}

	func onRatingChanged(_ rating: Int) {
		let ratingDescription = rating.description
		self.feedbackValues = self.feedback.ratingValueSelectList.first { value in
			value.value^.contains(ratingDescription)
		}

		let viewModel = self.viewModelForCurrentState
		self.viewController?.setup(with: viewModel)
	}

	private var viewModelForCurrentState: FeedbackViewModel {
		weak var wSelf = self

		var viewModel = FeedbackViewModel(
			state: .initial,
			taskIcon: self.feedback.taskType?.image,
			taskName: self.feedback.taskTitle,
			taskDate: self.feedback.taskSubtitle,
			onRatingChanged: { wSelf?.onRatingChanged($0) },
			onSubmit: { wSelf?.onSubmit(rating: $0, complaintsIndices: $1, comment: $2) },
			onFinish: { wSelf?.viewController?.dismiss(animated: true) }
		)

		if let feedbackValues = self.feedbackValues {
			viewModel.state = .details
			viewModel.complaintsTitle = feedbackValues.name
			viewModel.complaintsSubtitle = feedbackValues.description
			viewModel.complaints = feedbackValues.select^
		}

		return viewModel
	}

	private func onSubmit(rating: Int, complaintsIndices: [Int], comment: String?) -> Void {
		let value = self.feedback.ratingValueSelectList.first { $0.value^.contains(rating.description) }
		guard let value = value, let values = value.select else {
			return
		}

		let selectedValues = values.elements(at: complaintsIndices)

		let userFeedback = UserFeedback(
			comment: comment,
			rating: rating.description,
			selectValues: selectedValues
		)

		self.viewController?.showLoadingIndicator()

		let guid = self.feedback.guid^
		let taskId = Int(self.feedback.objectId^)

		selectedValues.forEach { value in
			AnalyticsReportingService.shared.didSelectFeedbackValue(rating: rating, value: value)
		}

		let feedbackString = userFeedback.jsonString^

		AnalyticsReportingService.shared.didSubmitFeedback(feedback: feedbackString)

		FeedbackEndpoint.shared.submit(new: userFeedback, guid: guid).promise
			.done { response in
				var viewModel = self.viewModelForCurrentState
				viewModel.state = .success
				self.viewController?.setup(with: viewModel)
				AnalyticsReportingService.shared.didReceiveFeedbackCreatedSuccessfully(feedback: feedbackString)
			}.ensure {
				self.viewController?.hideLoadingIndicator()
				var userInfo = [String: Any]()
				userInfo["guid"] = guid

				if let taskId = taskId { userInfo["taskId"] = taskId }
				Notification.post(.didSubmitFeedback, userInfo: userInfo)
			}.catch { error in
				AlertPresenter.alertCommonError()
			}
	}
}

extension Array {
	func elements(at indices: [Int]) -> [Element] {
		indices.map { self[$0] }
	}
}
