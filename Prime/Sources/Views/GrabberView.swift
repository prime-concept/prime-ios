import UIKit

extension GrabberView {
	struct Appearance: Codable {
		var grabberColor: ThemedColor
		var grabberHeight: CGFloat
		var grabberWidth: CGFloat

		init(
			color: ThemedColor = Palette.shared.gray3,
			height: CGFloat = 3,
			width: CGFloat = 35
		) {
			self.grabberColor = color
			self.grabberHeight = height
			self.grabberWidth = width
		}
	}
}

final class GrabberView: ChatKeyboardDismissingView {
	init(appearance: Appearance = Theme.shared.appearance()) {
		super.init(frame: .zero)

		let grabberStack = UIStackView.horizontal(
			.hSpacer(growable: 0),
			   UIStackView.vertical(
				   .vSpacer(growable: 0),
				   UIView { view in
					   view.backgroundColorThemed = appearance.grabberColor
					   view.layer.cornerRadius = appearance.grabberHeight / 2
					   view.make(.width, .equal, appearance.grabberWidth)
					   view.make(.height, .equal, appearance.grabberHeight)
				   }
			   ),
			   .hSpacer(growable: 0)
		   ).withZeroSpacersConstrainedEqual()

		self.addSubview(grabberStack)
		grabberStack.make(.edges, .equalToSuperview)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
