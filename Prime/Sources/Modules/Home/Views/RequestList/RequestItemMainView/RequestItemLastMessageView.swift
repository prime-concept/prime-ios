import UIKit

extension RequestItemLastMessageView {
    struct Appearance: Codable {
		var messageFont = Palette.shared.body4

        var dateTimeColor = Palette.shared.gray1
        var backgroundOutcomeColor = Palette.shared.gray5
        var backgroundIncomeColor = Palette.shared.gray4
        var contentColor = Palette.shared.gray0
		var tintColor = Palette.shared.brandSecondary
    }
}

final class RequestItemLastMessageView: UIView {
	private let appearance: Appearance

	private lazy var contentTextLabel = UILabel()
	private lazy var contentImageView = UIImageView()
	private lazy var contentImageViewContainer = UIImageView()

    private lazy var dateTimeLabel = UILabel()
	private lazy var unreadCountBadge = UnreadCountBadge()

    private lazy var sendingStatusImageView = UIImageView()
    private lazy var sendingStatusImageViewContainer = UIView()

	private lazy var messengerIconImageView = UIImageView { (imageView: UIImageView) in
		imageView.make(.size, .equal, [16, 16])
		imageView.contentMode = .scaleAspectFit
	}

	private lazy var draftStatusLabel = UILabel { (label: UILabel) in
		label.attributedTextThemed = Localization.localize("home.request.draft").attributed()
			.primeFont(ofSize: 13, lineHeight: 13)
			.foregroundColor(Palette.shared.draft)
			.string()
	}

	private lazy var draftStatusIconView = UIImageView { (imageView: UIImageView) in
		var image = UIImage(named: "request-draft-title-icon")
		imageView.image = image
		imageView.tintColorThemed = Palette.shared.draft
	}

    private lazy var draftStatusStackView = UIStackView(arrangedSubviews: [
		UIStackView.vertical(
			.vSpacer(1),
			self.draftStatusIconView,
			.vSpacer(growable: 0)
		),
		self.draftStatusLabel
	])

	private lazy var contentStackView = UIStackView(
		arrangedSubviews: [self.contentImageViewContainer, self.contentTextLabel]
	)

	private lazy var leftStackView = UIStackView(
		arrangedSubviews: [self.draftStatusStackView, self.contentStackView]
	)

    private lazy var rightStackView = UIStackView(
		arrangedSubviews: [
			.hSpacer(growable: 0),
			self.messengerIconImageView,
			.hSpacer(5),
			UIStackView.vertical(
				.vSpacer(growable: 0),
				self.dateTimeLabel,
				.vSpacer(1)
			),
			.hSpacer(2),
			self.sendingStatusImageViewContainer
		]
    )

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

	private static let cache = NSAttributedStringsCache()

	//ТОРМОЗА!
	func setup(with viewModel: RequestItemLastMessageViewModel) {
        self.draftStatusStackView.isHidden = viewModel.status != .draft


		self.dateTimeLabel.attributedTextThemed = Self.cache.string(for: "dateTimeLabel", raw: viewModel.dateTime) {
			viewModel.dateTime.attributed()
				.primeFont(ofSize: 12, lineHeight: 12)
				.foregroundColor(self.appearance.dateTimeColor)
				.string()
		}

		self.contentTextLabel.attributedTextThemed = Self.cache.string(for: "contentTextLabel", raw: viewModel.text) {
			viewModel.text.attributed()
				.themedFont(self.appearance.messageFont)
				.foregroundColor(self.appearance.contentColor)
				.lineBreakMode(.byTruncatingTail)
				.string()
		}

        if let image = viewModel.icon {
            self.contentImageView.image = image.withRenderingMode(.alwaysTemplate)
            self.contentImageView.tintColorThemed = self.appearance.contentColor
            self.contentImageView.snp.updateConstraints { make in
                make.width.height.equalTo(26)
            }
            self.contentImageViewContainer.isHidden = false
        } else if let image = viewModel.preview {
            self.contentImageView.image = image
            self.contentImageView.snp.updateConstraints { make in
                make.width.height.equalTo(30)
            }
            self.contentImageViewContainer.isHidden = false
        } else {
            self.contentImageViewContainer.isHidden = true
        }

		self.sendingStatusImageView.image = viewModel.statusImage
		self.sendingStatusImageViewContainer.isHidden = viewModel.statusImage == nil
		self.sendingStatusImageView.contentMode = .scaleAspectFit

		self.messengerIconImageView.image = viewModel.messengerIcon
		self.messengerIconImageView.isHidden = viewModel.messengerIcon == nil

        self.backgroundColorThemed = viewModel.isIncome
            ? self.appearance.backgroundIncomeColor
            : self.appearance.backgroundOutcomeColor

		self.unreadCountBadge.isHidden = viewModel.unreadCount == 0
		self.unreadCountBadge.update(
			with: UnreadCountBadge.ViewModel(
				text: viewModel.unreadCount.description,
				font: Palette.shared.primeFont.with(size: 12, weight: .medium),
				minTextHeight: 14,
				contentInsets: UIEdgeInsets(top: 4, left: 3, bottom: 2, right: 3)
			)
		)
    }
}

extension RequestItemLastMessageView: Designable {
    func setupView() {
        self.contentStackView.spacing = 10

        self.leftStackView.axis = .vertical
        self.leftStackView.spacing = 5

		self.draftStatusStackView.alignment = .top
        self.draftStatusStackView.spacing = 5

        self.contentTextLabel.numberOfLines = 0
        self.contentStackView.alignment = .center

		self.sendingStatusImageView.tintColorThemed = self.appearance.tintColor
    }

    func addSubviews() {
        self.sendingStatusImageViewContainer.addSubview(self.sendingStatusImageView)
        self.contentImageViewContainer.addSubview(self.contentImageView)
		self.addSubviews(
			self.leftStackView,
			self.rightStackView,
			self.unreadCountBadge
		)
    }

    func makeConstraints() {
		self.dateTimeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		self.contentTextLabel.setContentCompressionResistancePriority(.init(rawValue: 999), for: .horizontal)

		self.leftStackView.snp.makeConstraints { make in
			make.leading.equalToSuperview().offset(10)
			make.top.equalToSuperview().offset(5)
			make.trailing.lessThanOrEqualTo(self.rightStackView.snp.leading).offset(-10)
			make.bottom.equalToSuperview().offset(-5)
		}

        self.rightStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-6)
            make.bottom.equalToSuperview().offset(-5)
            make.top.greaterThanOrEqualToSuperview().offset(26)
        }

        self.sendingStatusImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 13, height: 9))
			make.bottom.equalToSuperview().inset(2)
            make.leading.trailing.equalToSuperview()
        }

        self.draftStatusIconView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 10, height: 10))
        }

        self.draftStatusStackView.snp.makeConstraints { make in
            make.height.equalTo(14)
        }

        self.contentImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize.zero)
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        self.contentTextLabel.snp.makeConstraints { make in
            make.height.lessThanOrEqualTo(56)
        }

		self.unreadCountBadge.snp.makeConstraints { make in
			make.top.trailing.equalToSuperview().inset(6)
			make.leading.greaterThanOrEqualTo(self.rightStackView)
			make.bottom.lessThanOrEqualTo(self.rightStackView.snp.top).offset(-6)
			make.height.equalTo(20)
			make.width.greaterThanOrEqualTo(20)
		}
    }
}
