import UIKit

final class UnreadCountBadge: UIView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.danger
        var labelTextColor = Palette.shared.gray5
    }
    
	struct ViewModel {
		let text: String
		let font: ThemedFont
		var minTextHeight: CGFloat?
		var contentInsets: UIEdgeInsets?
	}

	private lazy var label: UILabel = UILabel()
	private var viewModel: ViewModel?
	private lazy var widthConstraint = self.make(.width, .equal, 20, priority: .defaultHigh)
	private lazy var heightConstraint = self.make(.height, .equal, 20, priority: .defaultHigh)

    init(appearance: Appearance = Theme.shared.appearance()) {
        super.init(frame: .zero)
        self.label.textColorThemed = appearance.labelTextColor
        self.backgroundColorThemed = appearance.backgroundColor
		self.layer.masksToBounds = true
		self.addSubview(self.label)
	}

	convenience init(with viewModel: ViewModel) {
		self.init()
		self.update(with: viewModel)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.layer.cornerRadius = self.bounds.size.height / 2
	}

	func update(with viewModel: ViewModel) {
		self.viewModel = viewModel

		self.label.text = viewModel.text
		self.label.textAlignment = .center
		self.label.fontThemed = viewModel.font

		self.updateSize()
	}

	private func updateSize() {
		let rawLabelSize = self.label.sizeFor(width: .infinity)

		var labelHeight = ceil(rawLabelSize.height)
		let minLabelHeight = self.viewModel?.minTextHeight ?? 0
		labelHeight = max(minLabelHeight, labelHeight)

		let labelDefaultInset = floor(labelHeight / 4)
		let labelInsets = self.viewModel?.contentInsets ?? UIEdgeInsets(
			top: labelDefaultInset,
			left: labelDefaultInset,
			bottom: labelDefaultInset,
			right: labelDefaultInset
		)

		let labelWidth = max(labelHeight, rawLabelSize.width)
		let labelSize = CGSize(width: labelWidth, height: labelHeight)

		self.label.frame = CGRect(
			origin: CGPoint(x: labelInsets.left, y: labelInsets.top),
			size: labelSize
		).integral

		var newSize = self.label.bounds.size
		newSize.width += labelInsets.left + labelInsets.right
		newSize.height += labelInsets.top + labelInsets.bottom

		self.widthConstraint.constant = ceil(newSize.width)
		self.heightConstraint.constant = ceil(newSize.height)
	}
}

