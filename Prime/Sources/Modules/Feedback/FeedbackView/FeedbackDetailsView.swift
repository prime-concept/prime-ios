import UIKit

extension FeedbackDetailsView {
	struct Appearance: Codable  {
		var backgroundColor = Palette.shared.gray5

		var separatorColor = Palette.shared.gray3

		var complaintTitleFont = Palette.shared.smallTitle
		var complaintTitleColor = Palette.shared.gray0

		var complaintSubtitleFont = Palette.shared.body2
		var complaintSubtitleColor = Palette.shared.gray0
	}
}

final class FeedbackDetailsView: UIView {
	private let appearance: Appearance

	init(appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance

		super.init(frame: .zero)

		self.placeSubviews()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private(set) lazy var complaintTitleLabel = UILabel { (label: UILabel) in
		label.textAlignment = .center
		label.fontThemed = self.appearance.complaintTitleFont
		label.textColorThemed = self.appearance.complaintTitleColor
	}

	private(set) lazy var complaintSubtitleLabel = UILabel { (label: UILabel) in
		label.textAlignment = .center
		label.fontThemed = self.appearance.complaintSubtitleFont
		label.textColorThemed = self.appearance.complaintSubtitleColor
	}

	private(set) lazy var chipsControl = ChipsControl()

	private(set) lazy var complaintTextView = PrimeTextViewComponent(numberOfLines: 5)
	
	private func placeSubviews() {
		self.backgroundColorThemed = self.appearance.backgroundColor

		let stack = UIStackView.vertical(
			self.complaintTitleLabel,
			.vSpacer(8),
			self.complaintSubtitleLabel,
			.vSpacer(27),
			self.chipsControl,
			.vSpacer(20),
			self.complaintTextView,
			.vSpacer(growable: 0)
		)

		stack.alignment = .fill

		self.addSubview(stack)
		stack.make(.edges, .equalToSuperview)
	}
}
