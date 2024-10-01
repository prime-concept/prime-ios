protocol HomeFeedbackManagerDelegate: AnyObject {
    func displayableTaskWithID(_ taskID: Int) -> Task?
}
