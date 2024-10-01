import UIKit

extension FeedbackStarsContainer {
	struct Appearance: Codable {
		var ratingSubscriptsFont = Palette.shared.caption
		var ratingSubscriptsColor = Palette.shared.brandPrimary
	}
}

class FeedbackStarsContainer: UIView {
	private let appearance: Appearance
    private var alreadyRatedStars: Int?
	
    init(appearance: Appearance = Theme.shared.appearance(), alreadyRatedStars: Int? = nil) {
		self.appearance = appearance
        self.alreadyRatedStars = alreadyRatedStars
		super.init(frame: .zero)

		self.placeSubviews()
		self.isUserInteractionEnabled = true
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func placeSubviews() {
		self.addSubview(self.starsControl)
		
		self.starsControl.make([.top, .centerX, .bottom], .equalToSuperview, [0, 0, -21])
		self.make(.width, .greaterThanOrEqual, to: self.starsControl)

		self.addSubview(self.worstSubscriptLabel)
		self.worstSubscriptLabel.place(under: self.starsControl, +10)
		self.worstSubscriptLabel.make(.centerX, .equal, to: .leading, of: self.starsControl, +17)

		self.addSubview(self.bestSubscriptLabel)
		self.bestSubscriptLabel.place(under: self.starsControl, +10)
		self.bestSubscriptLabel.make(.centerX, .equal, to: .trailing, of: self.starsControl, -17)
	}

	private(set) lazy var worstSubscriptLabel = UILabel { (label: UILabel) in
		label.fontThemed = self.appearance.ratingSubscriptsFont
		label.textColorThemed = self.appearance.ratingSubscriptsColor
	}

	private(set) lazy var bestSubscriptLabel = UILabel { (label: UILabel) in
		label.fontThemed = self.appearance.ratingSubscriptsFont
		label.textColorThemed = self.appearance.ratingSubscriptsColor
	}

	private(set) lazy var starsControl = StarsControl(currentRating: 0, minRating: 0, alreadyRatedStars: alreadyRatedStars)
}

