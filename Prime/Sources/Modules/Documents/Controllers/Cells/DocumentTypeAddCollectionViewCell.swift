import UIKit

final class DocumentTypeAddCollectionViewCell: UICollectionViewCell, Reusable {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.contentView.backgroundColorThemed = Palette.shared.gray4
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 5

        let iconImageView = UIImageView(image: UIImage(named: "document_add"))
        iconImageView.tintColorThemed = Palette.shared.brandPrimary

        self.contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.center.equalToSuperview()
        }
    }
}