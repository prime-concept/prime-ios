/// Receives events from the `FeedbackView`.
///
/// + Views are not supposed to have as much logic as `FeedbackView` does.
/// + The entire Feedback module needs to be refactored, so different states (initial, expanded, completed) are implemented as separate view controllers.
/// + Once the refactoring is done, this protocol can be removed altogether, as the entire stack can be dismissed from within a child view controller.
protocol FeedbackViewDelegate: AnyObject {
    func feedbackViewDidPresentSuccessView(_ feedbackView: FeedbackView)
}
