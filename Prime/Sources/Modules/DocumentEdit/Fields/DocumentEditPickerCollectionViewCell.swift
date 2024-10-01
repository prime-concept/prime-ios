import UIKit

struct DocumentEditPickerModel {
    let title: String
    let values: [String]
    let selectedIndex: Int?
    let onSelect: (Int) -> Void
}

final class DocumentEditPickerCollectionViewCell: UICollectionViewCell, Reusable, UITextFieldDelegate {
    private lazy var titleLabel = UILabel()
    private lazy var valueLabel = UILabel()
    private lazy var separatorView = OnePixelHeightView()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "arrow_right"))
        view.contentMode = .scaleAspectFit
        view.tintColorThemed = Palette.shared.gray1
        return view
    }()

    private var model: DocumentEditPickerModel?

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
        self.valueLabel.attributedTextThemed = nil
    }

    func update(with value: String) {
        self.valueLabel.attributedTextThemed = Self.makeValue(value, isSelected: true)
    }

    func configure(with model: DocumentEditPickerModel, onTap: @escaping () -> Void) {
        self.model = model

        self.titleLabel.attributedTextThemed = Self.makeTitle(model.title)

        let value: String = {
            if let index = model.selectedIndex {
                return model.values[index]
            }
            return model.title
        }()
        self.valueLabel.attributedTextThemed = Self.makeValue(value, isSelected: model.selectedIndex != nil)

        self.contentView.addTapHandler(onTap)
    }

    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, lineHeight: 15)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }

    private static func makeValue(_ text: String, isSelected: Bool) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 20)
            .foregroundColor(Palette.shared.gray0.withAlphaComponent(isSelected ? 1.0 : 0.3))
            .string()
    }

    private func setupView() {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.valueLabel)
        self.contentView.addSubview(self.separatorView)
        self.contentView.addSubview(self.arrowView)

        self.titleLabel.numberOfLines = 1
        self.valueLabel.numberOfLines = 1

        self.separatorView.backgroundColorThemed = Palette.shared.gray3

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        self.valueLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(15)
            make.height.equalTo(21)
        }

        self.arrowView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
            make.size.equalTo(CGSize(width: 16, height: 10))
            make.leading.equalTo(self.valueLabel.snp.trailing).offset(15)
        }

        self.separatorView.snp.makeConstraints { make in
            make.top.equalTo(self.valueLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(15)
			make.bottom.equalToSuperview()
        }
    }
}
