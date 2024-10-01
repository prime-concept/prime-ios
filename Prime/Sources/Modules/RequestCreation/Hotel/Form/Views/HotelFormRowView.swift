import UIKit

extension HotelFormRowView {
    struct Appearance: Codable {
        var titleTextColor = Palette.shared.gray0
        var placeholderTextColor = Palette.shared.gray1
        var separatorColor = Palette.shared.gray3
		var tintColor = Palette.shared.brandSecondary
    }
}

final class HotelFormRowView: UIView {
	private lazy var iconImageView = UIImageView { (imageView: UIImageView) in
		imageView.tintColorThemed = self.appearance.tintColor
	}

    private lazy var titleLabel = UILabel()
    private lazy var separatorView = OnePixelHeightView()

    private let appearance: Appearance

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: HotelFormRowViewModel) {
        self.separatorView.isHidden = viewModel.isSeparatorHidden
        self.iconImageView.image = viewModel.field.iconImage

        let title = viewModel.value
        let placeholder = viewModel.field.placeholder
        let text = title^.isEmpty ? self.makePlaceholder(placeholder) : self.makeTitle(title^)
        self.titleLabel.attributedTextThemed = text
    }

    private func makePlaceholder(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 14, lineHeight: 17)
            .foregroundColor(self.appearance.placeholderTextColor)
            .lineBreakMode(.byTruncatingTail)
            .string()
    }

    private func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 14, lineHeight: 17)
            .foregroundColor(self.appearance.titleTextColor)
            .lineBreakMode(.byTruncatingTail)
            .string()
    }
}

extension HotelFormRowView: Designable {
    func setupView() {
        self.separatorView.backgroundColorThemed = self.appearance.separatorColor
    }

    func addSubviews() {
        [
            self.iconImageView,
            self.titleLabel,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.leading.equalToSuperview().offset(15)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(10)
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
