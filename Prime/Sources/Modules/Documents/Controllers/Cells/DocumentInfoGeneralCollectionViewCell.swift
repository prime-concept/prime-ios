import UIKit

final class DocumentInfoGeneralCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var nameLabel = UILabel()
    private lazy var numberLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.nameLabel.attributedTextThemed = nil
        self.numberLabel.attributedTextThemed = nil
    }

    static func height(for name: String, number: String, maxWidth: CGFloat) -> CGFloat {
        Self.makeNameText(name).size(maxSize: CGSize(width: maxWidth - 30, height: .nan)).height
            + Self.makeNumberText(number).size(maxSize: CGSize(width: maxWidth - 30, height: .nan)).height
            + 5
    }

    func configure(with name: String, number: String) {
        self.nameLabel.attributedTextThemed = Self.makeNameText(name)
        self.numberLabel.attributedTextThemed = Self.makeNumberText(number)
    }

    private static func makeNameText(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 16, lineHeight: 20)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }

    private static func makeNumberText(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 14, lineHeight: 16)
            .foregroundColor(Palette.shared.brandPrimary)
            .string()
    }

    private func setupView() {
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.numberLabel)

        self.nameLabel.numberOfLines = 0

        self.nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.numberLabel.snp.makeConstraints { make in
            make.top.equalTo(self.nameLabel.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}
