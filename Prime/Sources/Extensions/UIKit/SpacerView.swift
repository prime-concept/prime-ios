import UIKit

//swiftlint:disable all
class SpacerView: UIView {
    convenience init(_ axis: NSLayoutConstraint.Axis, _ constant: CGFloat) {
        self.init(axis, .equal, constant)
    }
    
    init(_ axis: NSLayoutConstraint.Axis, _ relation: NSLayoutConstraint.Relation, _ constant: CGFloat) {
        self.relation = relation
        self.constant = constant
        self.axis = axis
        
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        makeConstraint()
    }
    
    let axis: NSLayoutConstraint.Axis
    let relation: NSLayoutConstraint.Relation
    let constant: CGFloat
    
    private(set) var priority: UILayoutPriority?
    private var constraint: NSLayoutConstraint?
    
    @discardableResult
    func with(priority: UILayoutPriority) -> Self {
        self.priority = priority
        makeConstraint()
        return self
    }
    
    private func makeConstraint() {
        if let constraint = constraint {
            removeConstraint(constraint)
        }
        let nsAxis: NSLayoutConstraint.Axis = axis == .horizontal ? .horizontal : .vertical
        let nsAttribute: NSLayoutConstraint.Attribute = axis == .horizontal ? .width : .height
        
        setContentHuggingPriority(.defaultLow, for: nsAxis)
        setContentCompressionResistancePriority(.defaultHigh, for: nsAxis)
        let _constraint = NSLayoutConstraint(
			item: self,
			attribute: nsAttribute,
			relatedBy: relation,
			toItem: nil,
			attribute: .notAnAttribute,
			multiplier: 1.0,
			constant: constant
		)
        if let priority = priority { _constraint.priority = priority }
        addConstraint(_constraint)
        constraint = _constraint
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIStackView {
	convenience init(_ axis: NSLayoutConstraint.Axis, _ configBlock: (UIStackView) -> Void) {
		self.init(configBlock)
		self.axis = axis
	}

	static func vertical(spacing: CGFloat = 0, _ arrangedSubviews: UIView...) -> UIStackView {
		let stackView = UIStackView(.vertical)
		stackView.spacing = spacing
		stackView.addArrangedSubviews(arrangedSubviews)
		return stackView
	}

	static func vertical(spacing: CGFloat = 0, _ arrangedSubviews: [UIView]) -> UIStackView {
		let stackView = UIStackView(.vertical)
		stackView.spacing = spacing
		stackView.addArrangedSubviews(arrangedSubviews)
		return stackView
	}

	static func horizontal(spacing: CGFloat = 0, _ arrangedSubviews: UIView...) -> UIStackView {
		let stackView = UIStackView(.horizontal)
		stackView.spacing = spacing
		stackView.addArrangedSubviews(arrangedSubviews)
		return stackView
	}

	static func horizontal(spacing: CGFloat = 0, _ arrangedSubviews: [UIView]) -> UIStackView {
		let stackView = UIStackView(.horizontal)
		stackView.spacing = spacing
		stackView.addArrangedSubviews(arrangedSubviews)
		return stackView
	}

    @discardableResult
    func addArrangedSpacer(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> UIView {
        let spacer = SpacerView(axis, relation, constant)
        addArrangedSubview(spacer)
        return spacer
    }
    
    @discardableResult
    func addArrangedSpacer(shrinkable: CGFloat) -> UIView {
        return addArrangedSpacer(shrinkable, relation: .lessThanOrEqual)
    }
    
    @discardableResult
    func addArrangedSpacer(growable: CGFloat) -> UIView {
        return addArrangedSpacer(growable, relation: .greaterThanOrEqual)
    }

	func addArrangedSubviews(_ subviews: UIView...) {
		subviews.forEach(self.addArrangedSubview(_:))
	}
	func addArrangedSubviews(_ subviews: [UIView]) {
		subviews.forEach(self.addArrangedSubview)
	}

	func removeArrangedSubviews() {
		self.arrangedSubviews.forEach {
			self.removeArrangedSubview($0)
			$0.removeFromSuperview()
		}
	}

    func removeLastArrangedSubview() {
        if let lastArrangedSubview = self.arrangedSubviews.last {
            self.removeArrangedSubview(lastArrangedSubview)
            lastArrangedSubview.removeFromSuperview()
        }
    }

	convenience init(_ axis: NSLayoutConstraint.Axis) {
		self.init(frame: .zero)
		self.axis = axis
	}

	subscript(i: Int) -> UIView {
		self.arrangedSubviews[i]
	}

	@discardableResult
	func withZeroSpacersConstrainedEqual() -> UIStackView {
		let spacers = self.arrangedSubviews.filter {
			guard let spacer = $0 as? SpacerView,
					spacer.constant == 0,
					spacer.relation == .greaterThanOrEqual
			else {
				return false
			}
			return true
		}
		if spacers.count <= 1 {
			return self
		}

		for i in 1..<spacers.count {
			spacers[i].make(
				axis == .horizontal ? .width : .height,
				.equal,
				to: spacers[i-1]
			)
		}

		return self
	}
}

extension UIView {
	convenience init<T: UIView>(_ configBlock: (T) -> Void) {
		self.init(frame: .zero)
		if let self = self as? T {
			configBlock(self)
		}
	}
	static func hSpacer(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> UIView {
		SpacerView(.horizontal, relation, constant)
	}

	static func vSpacer(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> UIView {
		SpacerView(.vertical, relation, constant)
	}

	static func hSpacer(shrinkable: CGFloat) -> UIView {
		hSpacer(shrinkable, relation: .lessThanOrEqual)
	}

	static func vSpacer(shrinkable: CGFloat) -> UIView {
		vSpacer(shrinkable, relation: .lessThanOrEqual)
	}

	static func hSpacer(growable: CGFloat) -> UIView {
		hSpacer(growable, relation: .greaterThanOrEqual)
	}

	static func vSpacer(growable: CGFloat) -> UIView {
		vSpacer(growable, relation: .greaterThanOrEqual)
	}
}
//swiftlint:enable all
