import Foundation
import UIKit
import Nuke

extension CardsTableViewCell {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var countTextColor = Palette.shared.brandSecondary
        var separatorBackgroundColor = Palette.shared.gray3
        var titleTextColor = Palette.shared.gray0

        var emptyViewBackgroundColor = Palette.shared.gray4
        var emptyViewCornerRadius: CGFloat = 8
		var emptyCardColor = Palette.shared.custom_gray6

        var addBackgroundColor = Palette.shared.brandPrimary
        var addTintColor = Palette.shared.gray5
        var addCornerRadius: CGFloat = 10

        var contentContainerBackgroundColor = Palette.shared.gray5
        var contentContainerCornerRadius: CGFloat = 10
        var contentContainerShadowOffset = CGSize(width: 0, height: 5)
        var contentContainerShadowRadius: CGFloat = 15
        var contentContainerShadowColor = Palette.shared.black.withAlphaComponent(0.1)
        var contentContainerShadowOpacity: Float = 1
    }
}

final class CardsTableViewCell: UITableViewCell, Reusable {
    static let spacingBetweenCells: CGFloat = 1

    private lazy var arrowImageView: UIImageView = {
        let arrowImage = UIImage(named: "small_arrow")
        let imageView = UIImageView(image: arrowImage)
        return imageView
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorBackgroundColor
        return view
    }()

    private lazy var titleLabel = UILabel()
    private lazy var cardImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 3
        return imageView
    }()
    private let appearance: Appearance

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.appearance = Theme.shared.appearance()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: CardsViewModel, type: CardsTabType) {
        self.handle(viewModel: viewModel, type: type)
        if let url = URL(string: viewModel.image) {
            self.cardImageView.loadImage(from: url)
            self.cardImageView.backgroundColor = UIColor(hexString: viewModel.background)
        } else {
            self.cardImageView.backgroundColorThemed = appearance.emptyCardColor
        }
    }

    // MARK: - Helpers

    private func handle(viewModel: CardsViewModel, type: CardsTabType) {
        self.setNeedsLayout()
        self.layoutIfNeeded()

        if type == .loyalty {
            self.titleLabel.attributedTextThemed = viewModel.cardId.attributed()
                .foregroundColor(self.appearance.titleTextColor)
                .primeFont(ofSize: 15, weight: .regular, lineHeight: 18)
				.lineBreakMode(.byTruncatingTail)
                .string()
        }
    }
}

extension CardsTableViewCell: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.selectionStyle = .none
    }

    func addSubviews() {
        [
            self.cardImageView,
            self.titleLabel,
            self.arrowImageView,
            self.separatorView
        ].forEach(self.contentView.addSubview)
    }

    func makeConstraints() {
        self.cardImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(15)
            make.size.equalTo(CGSize(width: 46, height: 28))
			make.centerY.equalToSuperview()
        }
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.cardImageView.snp.trailing).offset(15)
            make.trailing.equalTo(self.arrowImageView.snp.leading).inset(-8)
            make.bottom.equalToSuperview().inset(14)
        }

        self.arrowImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 5.5, height: 10))
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
        }

        self.separatorView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
