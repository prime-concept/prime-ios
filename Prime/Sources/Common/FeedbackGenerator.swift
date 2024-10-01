import UIKit

enum FeedbackGenerator {
    static let vibrateLight: () -> Void = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()

        return {
            feedbackGenerator.impactOccurred()
        }
    }()

    static let vibrate: () -> Void = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()

        return {
            feedbackGenerator.impactOccurred()
        }
    }()

    static let vibrateSelection: () -> Void = {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()

        return {
            feedbackGenerator.selectionChanged()
        }
    }()
}
