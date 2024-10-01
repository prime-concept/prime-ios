import UIKit

final class PromoCategoryCollectionViewCell: UICollectionViewCell, Reusable {
	private lazy var itemView = HomePayItemView()

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.addSubviews()
		self.makeConstraints()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func addSubviews() {
		self.contentView.addSubview(self.itemView)
	}

	private func makeConstraints() {
		self.itemView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
	}

	func setup(with viewModel: PromoCategoryViewModel) {
		self.itemView.setup(
			title: viewModel.title,
			image: viewModel.image
		)
	}
}
