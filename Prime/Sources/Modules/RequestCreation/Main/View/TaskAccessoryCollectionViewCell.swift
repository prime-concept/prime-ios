import UIKit

final class TaskAccessoryCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var itemView = RequestItemMainView()

    override var isSelected: Bool {
        didSet {
            self.itemView.setSelected(isSelected)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ActiveTaskViewModel) {
		var viewModel = viewModel
		viewModel.hasReservation = false
		viewModel.isInputAccessory = true
        self.itemView.setup(with: viewModel)
    }
}

extension TaskAccessoryCollectionViewCell: Designable {
    func setupView() {
        self.backgroundColorThemed = Palette.shared.clear
        self.itemView.layer.cornerRadius = 5
        self.addShadow(height: 1, opacity: 0.35)
    }

    func addSubviews() {
        self.contentView.addSubview(self.itemView)
    }

    func makeConstraints() {
        self.itemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
