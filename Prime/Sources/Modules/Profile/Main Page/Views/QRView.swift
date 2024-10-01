import UIKit

extension QRView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var textColor = Palette.shared.gray0
        var cornerRadius: CGFloat = 3
		var tintColor = Palette.shared.black
    }
}

final class QRView: UIView {
    private lazy var QRImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
		imageView.tintColorThemed = self.appearance.tintColor
        return imageView
    }()

    private lazy var expiryDateLabel = UILabel()
    private let appearance: Appearance

    var qrCode: String? {
        didSet {
			onMain {
				self.QRImageView.image = self.qrCode?.qrImage(scale: 3)
			}
        }
    }

    var expiryDate: Date? {
        didSet {
            self.makeExpiryDateValue()
        }
    }

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeExpiryDateValue() {
        guard let expiryDate = self.expiryDate else { return }
        self.expiryDateLabel.attributedTextThemed = "\("profile.card.qr.expire".localized) \(expiryDate.string("dd.MM.yy"))".attributed()
            .foregroundColor(self.appearance.textColor)
            .primeFont(ofSize: 8, weight: .medium, lineHeight: 9.6)
            .alignment(.center)
            .string()
        self.expiryDateLabel.adjustsFontSizeToFitWidth = true
    }
}

extension QRView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.layer.cornerRadius = self.appearance.cornerRadius
    }

    func addSubviews() {
        [
            self.QRImageView,
            self.expiryDateLabel
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
		self.QRImageView.make(.height, .equal, to: .width, of: self.QRImageView)
		self.QRImageView.make([.top, .leading, .trailing], .equalToSuperview, [8, 8, -8])

        self.expiryDateLabel.snp.makeConstraints { make in
            make.top.equalTo(self.QRImageView.snp.bottom).offset(0)
			make.leading.trailing.bottom.equalToSuperview().inset(5)
        }
    }
}
