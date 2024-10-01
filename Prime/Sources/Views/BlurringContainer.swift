import UIKit

class BlurringContainer: UIView {

	let contentView: UIView

	let blurEffectView: UIVisualEffectView = {
		let blurEffectView = UIVisualEffectView()
		blurEffectView.backgroundColor = .clear
		blurEffectView.effect = UIBlurEffect(style: .regular)
		return blurEffectView
	}()

	let contentInsets: UIEdgeInsets

	init(with contentView: UIView, insets: UIEdgeInsets = .zero) {
		self.contentView = contentView
		self.contentInsets = insets

		super.init(frame: .zero)

		addSubview(blurEffectView)
		blurEffectView.contentView.addSubview(contentView)

		blurEffectView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}

		contentView.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(insets)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		adjustCornersIfNeeded()
	}

	private func adjustCornersIfNeeded() {
		if contentInsets == .zero {
			alignCornerRadiiToContent()
		}
	}

	func alignCornerRadiiToContent() {
		layer.masksToBounds = contentView.layer.masksToBounds
		layer.cornerRadius = contentView.layer.cornerRadius
	}
}
