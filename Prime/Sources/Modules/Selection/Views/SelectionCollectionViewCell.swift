import UIKit

final class SelectionCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var selectionItemView = SelectionItemView()

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
        self.contentView.addSubview(self.selectionItemView)
    }

    private func makeConstraints() {
        self.selectionItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

	func setup(value: String, description: String? = nil, isSelected: Bool) {
        self.selectionItemView.setup(
			value: value,
			description: description,
			isSelected: isSelected
		)
    }
}
