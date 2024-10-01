import UIKit

final class TasksListItemCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var tasksListItemView = RequestItemMainView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: CompletedTaskViewModel) {
        self.tasksListItemView.setup(with: viewModel)
    }
}

extension TasksListItemCollectionViewCell: Designable {
    func addSubviews() {
        self.contentView.addSubview(self.tasksListItemView)
    }

    func makeConstraints() {
        self.tasksListItemView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
            make.bottom.equalToSuperview().offset(-6)
        }
    }
}
