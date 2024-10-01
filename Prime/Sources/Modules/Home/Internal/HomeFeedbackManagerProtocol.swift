/// The object responsible for managing feedback objects.
protocol HomeFeedbackManagerProtocol: AnyObject {

    /// Returns the underlying collection of `ActiveFeedback`s as is.
    ///
    /// + This symbol only exists until the comprehensive refactoring of `HomePresenter` is finished.
    /// + Whenever possible, use `feedbackForTask(_:)` or `feedbackWithGUID(_:)` instead.
    var _rawFeedbacks: [ActiveFeedback] { get }

    /// Removes all existing feedbacks and replaces them with the new collection.
    ///
    /// - Parameter feedbacks: *Required.* An array of `ActiveFeedback`s.
    func replaceAllFeedbacks(with feedbacks: [ActiveFeedback])

    /// Returns an `ActiveFeedback` object matching the specified `Task` and enriched with its details.
    ///
    /// - Parameter task: *Required.* The `Task` object.
    func feedbackForTask(_ task: Task) -> ActiveFeedback?

    /// Returns an `ActiveFeedback` object matching the specified `Task` and enriched with its details.
    ///
    /// - Parameter guid: *Required.* The feedback’s GUID.
    func feedbackWithGUID(_ guid: String) -> ActiveFeedback?

    /// Returns an `ActiveFeedback` object matching the specified `Task` and enriched with its details.
    ///
    /// - Parameter taskID: *Required.* Corresponding TaskInfo's taskID.
    func feedbackWithTaskID(_ taskID: String) -> ActiveFeedback?
}
