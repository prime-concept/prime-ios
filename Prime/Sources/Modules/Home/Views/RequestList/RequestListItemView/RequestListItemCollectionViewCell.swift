import UIKit

final class RequestListItemCollectionViewCell: UICollectionViewCell, Reusable {
	private lazy var requestListItemView = RequestListItemView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(
		with viewModel: RequestListItemViewModel,
		onOrderViewTap: @escaping (Int) -> Void,
		onPromoCategoryTap: @escaping (Int) -> Void
	) {
        self.requestListItemView.setup(
			with: viewModel,
			onOrderViewTap: onOrderViewTap,
			onPromoCategoryTap: onPromoCategoryTap
		)
    }
}

extension RequestListItemCollectionViewCell: Designable {
    func addSubviews() {
        self.contentView.addSubview(self.requestListItemView)
        self.dropShadow(offset: .init(width: 0, height: 5), radius: 10, color: Palette.shared.mainBlack, opacity: 0.2)
    }

    func makeConstraints() {
        self.contentView.make(.edges, .equalToSuperview)
		self.requestListItemView.make(.vEdges, .equalToSuperview, [4, -6])
		self.requestListItemView.make(.hEdges, .equalToSuperview, [15, -15])
    }
}
