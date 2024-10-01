import UIKit

protocol RequestItemFeedbackView: UIView {
	func setup(with viewModel: RequestItemFeedbackViewModel)
}

extension DefaultRequestItemFeedbackView {
	struct Appearance: Codable {
		var tintColor = Palette.shared.brandSecondary
		var titleFont = Palette.shared.captionReg
		var titleColor = Palette.shared.gray0
	}
}

final class DefaultRequestItemFeedbackView: UIView, RequestItemFeedbackView {
	private let appearance: Appearance
	private lazy var titleLabel = UILabel { (label: UILabel) in
		label.adjustsFontSizeToFitWidth = true
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.titleColor
	}

	private lazy var stars: [UIImageView] = (0..<5).map { _ in
		let imageView = UIImageView(image: UIImage(named: "task_feedback_image_star_small"))
		imageView.make(.size, .equal, [12, 12])
		imageView.tintColorThemed = self.appearance.tintColor
		return imageView
	}

	private lazy var starsControl = UIView { view in
		view.layer.cornerRadius = 6
		view.layer.borderColorThemed = self.appearance.tintColor
		view.layer.borderWidth = 1 / UIScreen.main.scale

		let stack = UIStackView.horizontal(self.stars)
		stack.spacing = 2

		view.addSubview(stack)
		stack.make(.edges, .equalToSuperview, [12, 15, -12, -15])
	}

	init(frame: CGRect = .zero, appearance: Appearance = .init()) {
		self.appearance = appearance
		super.init(frame: frame)
		self.placeSubviews()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func placeSubviews() {
		self.addSubview(self.titleLabel)
		self.titleLabel.make([.leading, .centerY], .equalToSuperview, [10, 0])

		self.addSubview(self.starsControl)
		self.starsControl.place(behind: self.titleLabel, +15)
		self.starsControl.make(.edges(except: .leading), .equalToSuperview, [5, -5, -10])
	}

	func setup(with viewModel: RequestItemFeedbackViewModel) {
		self.titleLabel.text = viewModel.title
	}
}

extension DefaultRequestItemFeedbackView {
	static func standalone(
		title: String = "feedback.please.rate1".localized,
		taskId: Int,
		insets: [CGFloat] = [0, 0, 0, 0],
		autohide: Bool = true,
		onTapAdditional: (() -> Void)?
	) -> UIView {

		let instance = DefaultRequestItemFeedbackView()
		instance.setup(with: RequestItemFeedbackViewModel(title: title, taskCompleted: false))
		let container = instance.inset(insets)

		let separator = OnePixelHeightView()
		separator.backgroundColorThemed = Palette.shared.gray3

		container.addSubview(separator)
		separator.make(.edges(except: .bottom), .equalToSuperview)

		container.addTapHandler {
			onTapAdditional?()

			Notification.post(.didTapOnFeedback, userInfo: ["taskId": taskId])
			if !autohide { return }

			Notification.onReceive(.didSubmitFeedback, on: .main, uniqueBy: container) { [weak container] notification in
				let currentTaskId = taskId
				let taskId = notification.userInfo?["taskId"] as? Int

				guard let taskId = taskId, currentTaskId == taskId else {
					return
				}

				container?.isHidden = true
			}
		}

		return container
	}
}
