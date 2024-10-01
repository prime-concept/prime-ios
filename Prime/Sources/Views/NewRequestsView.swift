import UIKit

extension NewRequestsView {
    struct Appearance: Codable {
        var titleTextColor = Palette.shared.gray0
		var titleFont = Palette.shared.primeFont.with(size: 15, weight: .medium)

        var unreadMessageCountInsets = UIEdgeInsets(top: 5, left: 3, bottom: 3, right: 3)
        var unreadMessageCountTextColor = Palette.shared.gray5
        var unreadMessageCountBackgroundColor = Palette.shared.brandPrimary
        var unreadMessageCountCornerRadius: CGFloat = 10

        var backgroundColor = Palette.shared.gray5
        var cornerRadius: CGFloat = 10
        var borderWidth: CGFloat = 1
        var borderColor = Palette.shared.brandPrimary
		var separatorColor = Palette.shared.gray3

        var logoBorderWidth: CGFloat = 0.5
        var logoBorderColor = Palette.shared.brandSecondary
    }
}

final class NewRequestsView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.attributedTextThemed = Localization.localize("home.newRequests.title").attributed()
            .foregroundColor(self.appearance.titleTextColor)
			.font(self.appearance.titleFont)
			.lineHeight(13)
            .string()
        return label
    }()

    private lazy var logoView: TaskInfoTypeView = {
        let logoView = TaskInfoTypeView()
        logoView.set(image: UIImage(named: "new_requests"), insets: .tlbr(0, 0, 3, 0))
        return logoView
    }()

	private lazy var latestMessageView = RequestItemLastMessageView()

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

    func setup(with viewModel: RequestItemLastMessageViewModel?) {
		self.setup(latestMessage: viewModel)
    }

	private func setup(latestMessage: RequestItemLastMessageViewModel?) {
		self.latestMessageView.isHidden = latestMessage == nil
		guard let message = latestMessage else {
			self.latestMessageView.isHidden = true
			return
		}

		self.latestMessageView.setup(with: message)
	}
}

extension NewRequestsView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
		self.layer.masksToBounds = true
        self.layer.cornerRadius = self.appearance.cornerRadius
        self.layer.borderWidth = self.appearance.borderWidth
        self.layer.borderColorThemed = self.appearance.borderColor
        self.logoView.layer.borderWidth = self.appearance.logoBorderWidth
        self.logoView.layer.borderColorThemed = self.appearance.logoBorderColor
        self.dropShadow(offset: .init(width: 0, height: 5), radius: 10, color: Palette.shared.mainBlack, opacity: 0.2)

		self.latestMessageView.isHidden = true
		self.latestMessageView.layer.masksToBounds = true
		self.latestMessageView.layer.cornerRadius = self.appearance.cornerRadius
		self.latestMessageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

    func addSubviews() {
		let separator = OnePixelHeightView()
		separator.backgroundColorThemed = self.appearance.separatorColor
		self.latestMessageView.addSubview(separator)
		separator.make(.edges(except: .bottom), .equalToSuperview)
	}

    func makeConstraints() {
		let hStack = UIStackView(.horizontal)
		hStack.alignment = .center
		hStack.make(.height, .equal, 58)
		hStack.addArrangedSubviews(
			.hSpacer(10),
			self.logoView,
			.hSpacer(10),
			self.titleLabel,
			.hSpacer(15)
		)

		self.logoView.make(.size, .equal, [36, 36])

		let mainStack = UIStackView(.vertical)
		mainStack.addArrangedSubviews(
			hStack,
			self.latestMessageView
		)

		self.addSubview(mainStack)
		mainStack.make(.edges, .equalToSuperview)
    }
}

