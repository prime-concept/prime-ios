import UIKit

class ScrollableStack: UIScrollView {
	var axis: NSLayoutConstraint.Axis {
		get { self.stackView.axis }
		set { self.updateAxis(newValue) }
	}

	private(set) var stackView = UIStackView()
	private var widthConstraint: NSLayoutConstraint?
	private var heightConstraint: NSLayoutConstraint?

	private lazy var keyboardHeightTracker = PrimeKeyboardHeightTracker(view: self) { [weak self] height in
		self?.contentInset.bottom = height
	}

	init(_ axis: NSLayoutConstraint.Axis, arrangedSubviews: [UIView] = [], tracksKeyboard: Bool = false) {
		super.init(frame: .zero)

		self.translatesAutoresizingMaskIntoConstraints = false

		self.addSubview(self.stackView)
		self.stackView.make(.edges, .equalToSuperview)

		self.widthConstraint = self.stackView.make(.width, .equalToSuperview)
		self.heightConstraint = self.stackView.make(.height, .equalToSuperview)

		self.updateAxis(axis)
		self.setArrangedSubviews(arrangedSubviews)

		if tracksKeyboard {
			_ = self.keyboardHeightTracker
		}
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@discardableResult
	func addArrangedSpacer(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> UIView {
		self.stackView.addArrangedSpacer(constant, relation: relation)
	}

	@discardableResult
	func addArrangedSpacer(shrinkable: CGFloat) -> UIView {
		self.stackView.addArrangedSpacer(shrinkable: shrinkable)
	}

	@discardableResult
	func addArrangedSpacer(growable: CGFloat) -> UIView {
		self.stackView.addArrangedSpacer(growable: growable)
	}

	func addArrangedSubview(_ subview: UIView) {
		self.stackView.addArrangedSubview(subview)
	}

	func addArrangedSubviews(_ subviews: UIView...) {
		self.stackView.addArrangedSubviews(subviews)
	}

	func addArrangedSubviews(_ subviews: [UIView]) {
		self.stackView.addArrangedSubviews(subviews)
	}

	func setArrangedSubviews(_ subviews: UIView...) {
		self.removeArrangedSubviews()
		self.stackView.addArrangedSubviews(subviews)
	}

	func setArrangedSubviews(_ subviews: [UIView]) {
		self.removeArrangedSubviews()
		self.stackView.addArrangedSubviews(subviews)
	}

	func removeArrangedSubviews() {
		self.stackView.arrangedSubviews.forEach {
			self.stackView.removeArrangedSubview($0)
			$0.removeFromSuperview()
		}
	}

	private func updateAxis(_ axis: NSLayoutConstraint.Axis) {
		self.stackView.axis = axis

		self.widthConstraint?.isActive = axis == .vertical
		self.heightConstraint?.isActive = axis == .horizontal
	}
}
