import UIKit

extension ChatNavigationBar {
    struct Appearance: Codable {
        var roundBackgroundColor = Palette.shared.gray5
        var roundBorderWidth: CGFloat = 0.75
        var roundBorderColor = Palette.shared.brandSecondary
        var roundCornerRadius: CGFloat = 18

        var firstLetterFont = Palette.shared.primeFont.with(size: 13)
        var firstLetterTextColor = Palette.shared.brandSecondary

        var nameFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
		var nameTextColor = Palette.shared.chatAssistantNameColor

        var subtitleFont = Palette.shared.primeFont.with(size: 11)
        var subtitleTextColor = Palette.shared.gray1

        var phoneTintColor = Palette.shared.brandPrimary

        var grabberCornerRadius: CGFloat = 2
        var grabberBackgroundColor = Palette.shared.gray3

        var backgroundColor = Palette.shared.gray5
    }
}

final class ChatNavigationBar: ChatKeyboardDismissingView {
    private lazy var roundView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = self.appearance.roundBackgroundColor
        view.layer.borderWidth = self.appearance.roundBorderWidth
        view.layer.borderColorThemed = self.appearance.roundBorderColor
        view.layer.cornerRadius = self.appearance.roundCornerRadius
        return view
    }()

    private lazy var firstLetterLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.firstLetterFont
        label.textColorThemed = self.appearance.firstLetterTextColor
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.nameFont
        label.textColorThemed = self.appearance.nameTextColor
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.subtitleFont
        label.textColorThemed = self.appearance.subtitleTextColor
        return label
    }()

    private lazy var phoneButton: UIButton = {
        let button = UIButton()
        button.setImage(
            UIImage(named: "chat_phone_icon")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.tintColorThemed = self.appearance.phoneTintColor
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onPhoneTap?()
        }
        return button
    }()

    private lazy var grabberView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = self.appearance.grabberCornerRadius
        view.backgroundColorThemed = self.appearance.grabberBackgroundColor
        return view
    }()

    private let appearance: Appearance

    var onPhoneTap: (() -> Void)?

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

    func setup(with viewModel: ChatHeaderViewModel) {
        // swiftlint:disable:next prime_font
		let name = viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)
		let role = viewModel.role.trimmingCharacters(in: .whitespacesAndNewlines)

        self.nameLabel.text = name
        // swiftlint:disable:next prime_font
        self.subtitleLabel.text = role
		if let firstLetter = (name.first ?? role.first) {
            // swiftlint:disable:next prime_font
            self.firstLetterLabel.text = "\(firstLetter)"
        }

		self.nameLabel.isHidden = name.isEmpty
		self.subtitleLabel.isHidden = role.isEmpty
    }

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else {
			return super.touchesMoved(touches, with: event)
		}

		let location = touch.location(in: self)
		if self.phoneButton.frame.contains(location) {
			return
		}
	}
}

extension ChatNavigationBar: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        [
            self.grabberView,
            self.roundView,
            self.phoneButton
        ].forEach(self.addSubview)

        self.roundView.addSubview(self.firstLetterLabel)
    }

    func makeConstraints() {
        self.grabberView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 35, height: 3))
            make.top.equalToSuperview().offset(10)
        }

        self.roundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(9)
            make.bottom.equalToSuperview().offset(-7)

			let diameter = self.appearance.roundCornerRadius * 2
            make.size.equalTo(CGSize(width: diameter, height:diameter))
        }

        self.firstLetterLabel.snp.makeConstraints { make in
			make.centerX.equalToSuperview()

			let font = self.firstLetterLabel.font
			let bottom = font?.leading ?? 0

			make.centerY.equalToSuperview().offset(bottom)
        }

		let vStack = UIStackView.vertical (
			.vSpacer(growable: 0),
			self.nameLabel,
			self.subtitleLabel,
			.vSpacer(growable: 0)
		)

		vStack.spacing = 5
		let height = self.nameLabel.font.lineHeight + self.subtitleLabel.font.lineHeight + 3 * vStack.spacing

		self.addSubview(vStack)
		vStack.make([.bottom, .trailing], .equalToSuperview, [-4, -9])
		vStack.make(.leading, .equal, to: .trailing, of: self.roundView, +14)
		vStack.make(.height, .equal, height)
		vStack.arrangedSubviews[0].make(.height, .equal, to: vStack.arrangedSubviews[3])

        self.phoneButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-5)
            make.size.equalTo(CGSize(width: 44, height: 44))
			make.centerY.equalTo(self.roundView)
        }

		self.phoneButton.toFront()
    }
}
