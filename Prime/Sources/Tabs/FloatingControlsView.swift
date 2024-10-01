import UIKit

extension FloatingControlsView {
	struct Appearance: Codable {
		var barHeight: CGFloat = 50
		var barBackgroundColor = Palette.shared.gray5
		var barBorderColor = Palette.shared.gray3
		var barBorderWidth: CGFloat = 1

		var barButtonsTintNormalColor = Palette.shared.gray2
		var barButtonsTintSelectedColor = Palette.shared.brandSecondary
		var barButtonsBackgroundSelectedColor = Palette.shared.brandPrimary

		var bellHeight: CGFloat = 50
		var bellBackgroundColor = Palette.shared.mainButton
		var bellHighlightedColor = Palette.shared.mainButton
		var bellBorderColor = Palette.shared.brandSecondary
        var badgeBorderColor = Palette.shared.gray5
		var bellBorderWidth: CGFloat = 1
		var bellTintColor = Palette.shared.gray5

		var shadowColor = Palette.shared.mainBlack
	}
}

final class FloatingControlsView: UIView {
	static let shared = FloatingControlsView()

	private let appearance: Appearance
	var onBellPressed: (() -> Void)?

	var onDebugPressed: (() -> Void)?
	var onGlobePressed: (() -> Void)?
	var onImPrimePressed: (() -> Void)?

	private lazy var contentView = UIStackView.vertical(
		UIStackView.horizontal(.hSpacer(growable: 0), self.bellButton),
		.vSpacer(5),
		UIStackView { (stack: UIStackView) in
			stack.addArrangedSubviews(
				.hSpacer(3), self.debugButton, self.globeButton, self.iAmPrimeButton, .hSpacer(3)
			)

			stack.axis = .horizontal
			stack.make(.height, .equal, self.appearance.barHeight)
			stack.alignment = .center

			let bar = UIView { bar in
				bar.clipsToBounds = true
				bar.layer.cornerRadius = self.appearance.barHeight / 2
				bar.layer.borderColorThemed = self.appearance.barBorderColor
				bar.layer.borderWidth = self.appearance.barBorderWidth / UIScreen.main.scale
				bar.backgroundColorThemed = self.appearance.barBackgroundColor
			}

			stack.addSubview(bar)
			bar.toBack()
			bar.make(.edges, .equalToSuperview)
			bar.dropShadow(color: self.appearance.shadowColor)
		}
	)

	private init(appearance: Appearance = Theme.shared.appearance()) {
		self.appearance = appearance

		super.init(frame: UIScreen.main.bounds)

		self.addSubview(self.contentView)
		self.contentView.make([.bottom, .trailing], .equal, to: self.safeAreaLayoutGuide, [-15, -10])
	}
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let point = self.convert(point, to: self.contentView)
		return self.contentView.point(inside: point, with: event)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    private lazy var unreadCountBadge = UnreadCountBadge()

	private(set) lazy var bellButton = UIView { button in
        
        let backgroundView = UIView()
        backgroundView.make(.size, .equal, [self.appearance.bellHeight])
        backgroundView.backgroundColorThemed = Palette.shared.gray5
        backgroundView.dropShadow(color: self.appearance.shadowColor)
        backgroundView.layer.cornerRadius = self.appearance.bellHeight / 2
        backgroundView.layer.borderColorThemed = self.appearance.bellBorderColor
        backgroundView.layer.borderWidth = self.appearance.bellBorderWidth
        backgroundView.clipsToBounds = true

		let view = UIView()
        backgroundView.addSubview(view)
		view.make(.edges, .equalToSuperview)
		view.backgroundColorThemed = self.appearance.bellBackgroundColor
        view.clipsToBounds = true
		let image = UIImage(named: "tabbar_task")?.withRenderingMode(.alwaysTemplate)
		let imageView = UIImageView(image: image)
		imageView.tintColorThemed = self.appearance.bellTintColor

		view.addSubview(imageView)
		imageView.make(.center, .equalToSuperview, [0, -2])
        
        button.make(.size, .equal, [self.appearance.bellHeight])
        
        unreadCountBadge.layer.borderWidth = self.appearance.barBorderWidth
        unreadCountBadge.layer.borderColorThemed = self.appearance.badgeBorderColor
        
        button.addSubview(backgroundView)
        button.addSubview(unreadCountBadge)

        makeConstraints()
		view.addTapHandler { [weak self] in
			self?.onBellPressed?()
		}
	}
    
    func makeConstraints() {
        self.unreadCountBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(-10)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(22)
        }
    }

	private(set) lazy var debugButton = with(self.button(
		text: "🪲", // bug icon, жук
		action: { [weak self] in self?.onDebugPressed?() }
	)) { button in
		button.isHidden = !UserDefaults[bool: "bugIsVisible"]
		Notification.onReceive(.bugVisibilityChanged) { _ in
			button.isHidden = !UserDefaults[bool: "bugIsVisible"]
		}
	}

	private(set) lazy var globeButton = self.button(
		isRounded: true,
		imageName: "tabbar_navigator", // traveller icon, globe icon, глобус
		action: { self.onGlobePressed?() }
	)

	private(set) lazy var iAmPrimeButton = self.button(
		backgroundColor: self.appearance.barButtonsBackgroundSelectedColor,
		tintColor: self.appearance.barButtonsTintSelectedColor,
		isRounded: true,
		imageName: "tabbar_iam", // i am , iam, i'm
		action: { self.onImPrimePressed?() }
	)

	func show(animated: Bool = true) {
		UIView.animate(withDuration: animated ? 0.25 : 0) {
			self.alpha = 1.0
		}
	}

	func hide(animated: Bool = true) {
		UIView.animate(withDuration: animated ? 0.25 : 0) {
			self.alpha = 0.0
		}
	}
    
    func setUnreadCount(_ unreadCount: Int) {
        guard unreadCount > 0 else {
            self.unreadCountBadge.isHidden = true
            return
        }
		
        self.unreadCountBadge.isHidden = false
        self.unreadCountBadge.update(
            with: UnreadCountBadge.ViewModel(
                text: "\(unreadCount)",
                font: Palette.shared.primeFont.with(size: 12, weight: .medium),
                minTextHeight: 14,
                contentInsets: UIEdgeInsets(top: 4, left: 4, bottom: 2, right: 4)
            )
        )
    }
}

extension FloatingControlsView {
	private func button(
		size: CGFloat = 44,
		backgroundColor: ThemedColor = Palette.shared.clear,
		tintColor: ThemedColor? = nil,
		isRounded: Bool = false,
		text: String? = nil,
		imageName: String? = nil,
		action: @escaping () -> Void
	) -> UIView {
		let button = UIView()
		button.backgroundColorThemed = backgroundColor

		button.make(.size, .equal, [size, size])
		button.addTapHandler(action)

		if isRounded {
			button.layer.cornerRadius = size / 2
			button.layer.masksToBounds = true
		}

		if let text = text {
			let label = UILabel()
			label.font = .systemFont(ofSize: 30)
			label.text = text

			button.addSubview(label)
			label.make(.center, .equalToSuperview)
		}

		let tint = tintColor ?? self.appearance.barButtonsTintNormalColor

		if let imageName = imageName {
			let image = UIImage(named: imageName)
			let imageView = UIImageView(image: image)
			imageView.tintColorThemed = tint
			button.addSubview(imageView)
			imageView.make(.center, .equalToSuperview)
		}

		return button
	}
}

private extension UIView {
	func dropShadow(color: ThemedColor) {
		self.dropShadow(
			offset: CGSize(width: 0, height: 5),
			radius: 9,
			color: color,
			opacity: 0.10
		)
	}
}
