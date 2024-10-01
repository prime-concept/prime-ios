import UIKit

final class ContactTypeSelectionCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var contactTypeSelectionItemView = ContactTypeSelectionItemView()

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
        self.addSubview(self.contactTypeSelectionItemView)
    }

    private func makeConstraints() {
        self.contactTypeSelectionItemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setup(with viewModel: ContactTypeViewModel) {
        self.contactTypeSelectionItemView.setup(with: viewModel)
    }
}
