import UIKit

extension ContactAdditionSwitchFieldView {
	struct Appearance: Codable {
		var switchOnTint = Palette.shared.brandPrimary
		var textColor = Palette.shared.gray0
		var backgroundColor = Palette.shared.gray5
	}
}

class ContactAdditionSwitchFieldView: UIView {
	private let appearance: Appearance
	private lazy var titleLabel = UILabel()
	private lazy var switcher = with(UISwitch()) { switcher in
		switcher.onTintColorThemed = self.appearance.switchOnTint
	}

	var onSwitchChanged: ((String) -> Void)? {
		didSet {
			self.onSwitchChanged?(self.output)
		}
	}

	var output: String {
		self.switcher.isOn ? "true" : "false"
	}

	override var intrinsicContentSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: 55)
	}

	init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance
		super.init(frame: frame)

		self.setupView()
		self.addSubviews()
		self.makeConstraints()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup(with viewModel: ContactAdditionFieldViewModel) {
		self.titleLabel.attributedTextThemed = viewModel.type.text.attributed()
			.foregroundColor(self.appearance.textColor)
			.primeFont(ofSize: 15, lineHeight: 18)
			.string()
		self.switcher.isOn = viewModel.value == "true"
		self.onSwitchChanged?(viewModel.value)
	}
}

extension ContactAdditionSwitchFieldView: Designable {
	func setupView() {
		self.switcher.setEventHandler(for: .valueChanged, action: { [weak self] in
			self.some { (self) in
				self.onSwitchChanged?(self.output)
			}
		})
	}

	func addSubviews() {
		self.addSubview(self.titleLabel)
		self.addSubview(self.switcher)
	}

	func makeConstraints() {
		self.titleLabel.make([.top, .leading], .equalToSuperview, [20, 15])
		self.titleLabel.make(.trailing, .equal, to: .leading, of: self.switcher, -15)
		self.switcher.make(.centerY, .equal, to: self.titleLabel)
		self.switcher.make(.trailing, .equalToSuperview, -15)
	}
}
