import UIKit

final class DocumentInfoOneColumnCollectionViewCell: UICollectionViewCell, Reusable {
    private lazy var titleLabel = UILabel()
    private lazy var textLabel = UILabel()

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
        self.titleLabel.attributedTextThemed = nil
        self.textLabel.attributedTextThemed = nil
    }

    static func height(for title: String, text: String, maxWidth: CGFloat) -> CGFloat {
        Self.makeTitle(title).size(maxSize: CGSize(width: maxWidth - 30, height: .nan)).height
            + Self.makeText(text).size(maxSize: CGSize(width: maxWidth - 30, height: .nan)).height
            + 2
    }

    func configure(with title: String, text: String) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(title)
        self.textLabel.attributedTextThemed = Self.makeText(text)
    }

    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, lineHeight: 16)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }

    private static func makeText(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 16, lineHeight: 20)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }

    private func setupView() {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textLabel)

        self.titleLabel.numberOfLines = 0
        self.textLabel.numberOfLines = 0

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.textLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}
