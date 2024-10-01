import UIKit

final class DocumentInfoSeparatorCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var separatorView = OnePixelHeightView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.separatorView.backgroundColorThemed = Palette.shared.gray3
        self.contentView.addSubview(self.separatorView)

        self.separatorView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}
