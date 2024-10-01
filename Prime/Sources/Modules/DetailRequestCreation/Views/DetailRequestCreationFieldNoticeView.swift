import UIKit

extension DetailRequestCreationFieldNoticeView {
	struct Appearance: Codable {
		var titleFont = Palette.shared.primeFont.with(size: 12)
		var titleColor = Palette.shared.gray1
	}
}

final class DetailRequestCreationFieldNoticeView: UIView, TaskFieldValueInputProtocol {
	private lazy var titleLabel: UILabel = {
		let label = UILabel()
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.titleColor
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		return label
	}()

	private let appearance: Appearance

	init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance
		super.init(frame: frame)

		self.addSubviews()
		self.makeConstraints()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup(with viewModel: TaskCreationFieldViewModel) {
		// swiftlint:disable:next prime_font
		self.titleLabel.text = viewModel.title
	}
}

extension DetailRequestCreationFieldNoticeView: Designable {
	func addSubviews() {
		self.addSubview(self.titleLabel)
	}

	func makeConstraints() {
		self.titleLabel.snp.makeConstraints { make in
			make.edges.equalToSuperview()
				.inset(UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15))
		}
	}
}
