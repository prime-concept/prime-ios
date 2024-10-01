import UIKit

final class DocumentEditCountryPickerCollectionViewCell: UICollectionViewCell, Reusable {
	private lazy var arrowView: UIImageView = {
		let view = UIImageView(image: UIImage(named: "arrow_right"))
		view.contentMode = .scaleAspectFit
		view.isHidden = true
		view.tintColorThemed = Palette.shared.gray1
		return view
	}()

	private lazy var titleLabel = UILabel()
	private lazy var textField = UITextField()
	private lazy var separatorView = OnePixelHeightView()

	private var model: DocumentEditTextFieldModel?

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
		self.textField.attributedTextThemed = nil
		self.contentView.removeTapHandler()
	}

    func configure(with model: DocumentEditCountryPickerModel) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(model.title)
        self.textField.attributedPlaceholder = Self.makePlaceholder(model.placeholder)
        self.textField.attributedTextThemed = Self.makeValue(model.value)
        self.textField.isEnabled = false
        self.arrowView.isHidden = false
        self.contentView.addTapHandler(model.pickerInvoker)
    }

	private static func makeTitle(_ text: String) -> NSAttributedString {
		text.attributed()
			.primeFont(ofSize: 12, lineHeight: 15)
			.foregroundColor(Palette.shared.gray1)
			.string()
	}

	private static func makePlaceholder(_ text: String) -> NSAttributedString {
		text.attributed()
			.primeFont(ofSize: 15, lineHeight: 18)
			.foregroundColor(Palette.shared.gray0.withAlphaComponent(0.3))
			.string()
	}

	private static func makeValue(_ text: String) -> NSAttributedString {
		text.attributed()
			.primeFont(ofSize: 15, lineHeight: 18)
			.foregroundColor(Palette.shared.gray0)
			.string()
	}

	private func setupView() {
		self.contentView.addSubview(self.titleLabel)
		self.contentView.addSubview(self.textField)
		self.contentView.addSubview(self.separatorView)
		self.contentView.addSubview(self.arrowView)

		self.titleLabel.numberOfLines = 1

		self.textField.tintColorThemed = Palette.shared.gray0

		self.separatorView.backgroundColorThemed = Palette.shared.gray3

		self.titleLabel.snp.makeConstraints { make in
			make.top.equalToSuperview().offset(10)
			make.leading.trailing.equalToSuperview().inset(15)
		}

		self.textField.snp.makeConstraints { make in
			make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
			make.leading.trailing.equalToSuperview().inset(15)
			make.height.equalTo(21)
		}

		self.arrowView.snp.makeConstraints { make in
			make.centerY.equalToSuperview()
			make.trailing.equalToSuperview().inset(15)
			make.size.equalTo(CGSize(width: 16, height: 10))
		}

		self.separatorView.snp.makeConstraints { make in
			make.top.equalTo(self.textField.snp.bottom).offset(10)
			make.leading.trailing.equalToSuperview().inset(15)
			make.bottom.equalToSuperview()
		}
	}
}
