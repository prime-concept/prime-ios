import UIKit

final class DocumentInfoTwoColumnCollectionViewCell: UICollectionViewCell, Reusable {
    typealias Column = (title: String, text: String)

    private lazy var leftTitleLabel = UILabel()
    private lazy var leftTextLabel = UILabel()

    private lazy var rightTitleLabel = UILabel()
    private lazy var rightTextLabel = UILabel()

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
        self.leftTitleLabel.attributedTextThemed = nil
        self.leftTextLabel.attributedTextThemed = nil
        self.rightTitleLabel.attributedTextThemed = nil
        self.rightTextLabel.attributedTextThemed = nil
    }

    static func height(for leftColumn: Column, rightColumn: Column, maxWidth: CGFloat) -> CGFloat {
        let columnHeight = (maxWidth - 30 - 16) / 2
        let titleHeight = max(
            Self.makeTitle(leftColumn.title).size(maxSize: CGSize(width: columnHeight, height: .nan)).height,
            Self.makeTitle(rightColumn.title).size(maxSize: CGSize(width: columnHeight, height: .nan)).height
        )
        let textHeight = max(
            Self.makeText(leftColumn.text).size(maxSize: CGSize(width: columnHeight, height: .nan)).height,
            Self.makeText(rightColumn.text).size(maxSize: CGSize(width: columnHeight, height: .nan)).height
        )

        return textHeight + titleHeight + 2
    }

    func configure(with leftColumn: Column, rightColumn: Column) {
        self.leftTitleLabel.attributedTextThemed = Self.makeTitle(leftColumn.title)
        self.rightTitleLabel.attributedTextThemed = Self.makeTitle(rightColumn.title)

        self.leftTextLabel.attributedTextThemed = Self.makeText(leftColumn.text)
        self.rightTextLabel.attributedTextThemed = Self.makeText(rightColumn.text)
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
        let titleContainerView = UIView()
        let textContainerView = UIView()

        self.contentView.addSubview(titleContainerView)
        self.contentView.addSubview(textContainerView)

        titleContainerView.addSubview(self.leftTitleLabel)
        titleContainerView.addSubview(self.rightTitleLabel)
        textContainerView.addSubview(self.leftTextLabel)
        textContainerView.addSubview(self.rightTextLabel)

        self.leftTitleLabel.numberOfLines = 0
        self.rightTitleLabel.numberOfLines = 0
        self.leftTextLabel.numberOfLines = 0
        self.rightTextLabel.numberOfLines = 0

        titleContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(15)
        }

        textContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleContainerView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.leftTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().priority(.low)
            make.trailing.equalTo(self.rightTitleLabel.snp.leading).offset(-16)
            make.bottom.lessThanOrEqualToSuperview()
            make.width.equalTo(titleContainerView).offset(-8).multipliedBy(0.5)
        }

        self.rightTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().priority(.low)
            make.bottom.lessThanOrEqualToSuperview()
            make.width.equalTo(titleContainerView).offset(-8).multipliedBy(0.5)
        }

        self.leftTextLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().priority(.low)
            make.trailing.equalTo(self.rightTextLabel.snp.leading).offset(-16)
            make.bottom.lessThanOrEqualToSuperview()
            make.width.equalTo(textContainerView).offset(-8).multipliedBy(0.5)
        }

        self.rightTextLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().priority(.low)
            make.bottom.lessThanOrEqualToSuperview()
            make.width.equalTo(textContainerView).offset(-8).multipliedBy(0.5)
        }
    }
}
