import SnapKit
import UIKit

extension HomePayItemView {
    struct Appearance: Codable {
		var titleFont = Palette.shared.caption
		var subtitleFont = Palette.shared.caption2

        var titleTextColor = Palette.shared.brandSecondary
		var subtitleTextColor = Palette.shared.brandSecondary

        var highlightedTitleTextColor = Palette.shared.danger
        var highlightedSubtitleTextColor = Palette.shared.danger

        var borderWidth: CGFloat = 0.5
        var borderColor = Palette.shared.brandSecondary
        var highlightedBorderColor = Palette.shared.danger

        var imageTintColor = Palette.shared.brandSecondary
        var highlightedImageTintColor = Palette.shared.danger
        var cornerRadius: CGFloat = 6
    }
}

final class HomePayItemView: UIView {
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
		imageView.make(.size, .equal, [16, 16])
        return imageView
    }()

    private lazy var titleLabel = UILabel()
    private lazy var subtitleLabel = UILabel()
    private let appearance: Appearance

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
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

    func setup(with viewModel: HomePayItemViewModel) {
        self.setup(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
			image: viewModel.image,
            isHighlighted: viewModel.isHighlighted
        )
    }

    func setup(with viewModel: TasksListPayItemViewModel, onTap: @escaping () -> Void) {
        self.setup(
            title: viewModel.title,
			subtitle: viewModel.subtitle,
			image: nil,
            isHighlighted: viewModel.isHighlighted
        )

        self.addTapHandler(feedback: .scale, onTap)
        self.imageView.snp.removeConstraints()
    }

    // MARK: - Helpers

	private static let cache = NSAttributedStringsCache()

    func setup(
        title: String?,
        subtitle: String? = nil,
		image: UIImage? = nil,
        isHighlighted: Bool = false
    ) {
		let title = title ?? ""
		let subtitle = subtitle ?? ""

		self.layer.borderColorThemed = (
			isHighlighted
				? self.appearance.highlightedBorderColor
				: self.appearance.borderColor
		)

		let forceMultiline = title.contains("[\\s&]")
		let lineBreakMode: NSLineBreakMode = forceMultiline ? .byWordWrapping : .byTruncatingTail
		let numberOfLines = forceMultiline ? 2 : 1

		self.titleLabel.attributedTextThemed = Self.cache.string(for: "titleLabel", raw: title) {
			title.attributed()
				.foregroundColor(self.appearance.titleTextColor)
				.themedFont(self.appearance.titleFont)
				.alignment(.right)
				.lineBreakMode(lineBreakMode)
				.string()
		}

		self.titleLabel.lineBreakMode = lineBreakMode
		self.titleLabel.numberOfLines = numberOfLines

		self.subtitleLabel.attributedTextThemed = Self.cache.string(for: "subtitleLabel", raw: subtitle) {
			subtitle.attributed()
				.foregroundColor(self.appearance.subtitleTextColor)
				.themedFont(self.appearance.subtitleFont)
				.alignment(.right)
				.string()
		}

		self.imageView.image = image?.withRenderingMode(.alwaysTemplate)
		self.imageView.isHidden = image == nil
		self.imageView.tintColorThemed = isHighlighted
			? self.appearance.highlightedImageTintColor
			: self.appearance.imageTintColor

        self.titleLabel.textColorThemed = isHighlighted
            ? self.appearance.highlightedTitleTextColor
            : self.appearance.titleTextColor

        self.subtitleLabel.textColorThemed = isHighlighted
            ? self.appearance.highlightedSubtitleTextColor
            : self.appearance.subtitleTextColor

		self.titleLabel.isHidden = title.isEmpty
		self.subtitleLabel.isHidden = subtitle.isEmpty
    }
}

extension HomePayItemView: Designable {
    func setupView() {
        self.layer.cornerRadius = self.appearance.cornerRadius
        self.layer.borderWidth = self.appearance.borderWidth
        self.layer.borderColorThemed = self.appearance.borderColor

        self.titleLabel.setContentHuggingPriority(.init(rawValue: 250), for: .vertical)
        self.subtitleLabel.setContentHuggingPriority(.init(rawValue: 251), for: .vertical)
    }

    func addSubviews() {
		self.addSubview(self.imageView)
    }

    func makeConstraints() {
		self.titleLabel.make(resist: 751, axis: .horizontal)
		self.subtitleLabel.make(resist: 751, axis: .horizontal)

		let vStack = UIStackView.vertical(
			self.titleLabel,
			self.subtitleLabel
		)

		let hStack = UIStackView.horizontal(
			self.imageView, vStack
		)
		hStack.spacing = 12
		hStack.alignment = .center

		self.addSubview(hStack)
		hStack.make(.edges, .equalToSuperview, [0, 7, 0, -5])
		hStack.make(.centerY, .equalToSuperview)
		
		self.make(.height, .equal, 36, priority: .defaultHigh)
    }
}



