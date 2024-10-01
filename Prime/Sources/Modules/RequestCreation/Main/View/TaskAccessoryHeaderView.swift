import UIKit

extension TaskAccessoryButton {
	struct Appearance: Codable {
		var titleFont = Palette.shared.primeFont.with(size: 13, weight: .medium)
		var imageViewSize = CGSize(width: 14, height: 14)
		var contentInset: CGFloat = 8

		var backgroundColor = Palette.shared.gray5
		var backgroundColorHighlighted = Palette.shared.brandPrimary
		var tintColor = Palette.shared.gray0
		var tintColorHighlighted = Palette.shared.gray5
		var titleColor = Palette.shared.gray0
		var titleColorHighlighted = Palette.shared.gray5
	}
}


// swiftlint:disable trailing_whitespace
class TaskAccessoryButton: UIButton {
	private var appearance: Appearance = Theme.shared.appearance()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setup()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.updateColors()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.updateColors()
			self.isUserInteractionEnabled = !self.isSelected
        }
    }
    
    override var intrinsicContentSize: CGSize {
		let titleSize = self.titleSize
		var imageSize = CGSize.zero

		if let imageView, !imageView.isHidden {
			imageSize = imageView.image?.size ?? .zero
		}

		if imageSize == .zero {
			return CGSize(
				width: max(125, 21 + titleSize.width + 21),
				height: 32
			)
		}

		return CGSize(
			width: max(125, 21 + imageSize.width + 5 + titleSize.width + 21),
			height: 32
		)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

		let titleSize = self.titleSize
		var totalWidth = titleSize.width

		var imageSize = CGSize.zero
		if let imageView, !imageView.isHidden {
			imageSize = imageView.image?.size ?? .zero
		}

		if imageSize.width > 0 {
			totalWidth += imageSize.width
			totalWidth += 5
		}

		self.titleLabel?.bounds.size = titleSize
		self.titleLabel?.frame.origin.x = (self.bounds.width - totalWidth) / 2
		self.titleLabel?.frame.origin.y = (self.bounds.height - titleSize.height) / 2 + 0.5

		if imageSize.width > 0 {
			self.imageView?.frame.origin.x = (self.bounds.width - totalWidth) / 2
			self.imageView?.frame.origin.y = (self.bounds.height - imageSize.height) / 2
			self.titleLabel?.frame.origin.x += 5
			self.titleLabel?.frame.origin.x += imageSize.width
		}
    }

	private var titleSize: CGSize {
		guard let titleLabel = titleLabel,
			  let title = titleLabel.text else {
			return .zero
		}
		return title.size(using: self.appearance.titleFont.rawValue)
	}
    
    func update(with viewModel: TaskAccessoryHeaderViewModel.Button) {
        if let imageName = viewModel.imageName {
            let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
            self.setImage(image, for: .normal)
        } else {
            self.setImage(nil, for: .normal)
        }
        
        self.isUserInteractionEnabled = !self.isSelected
        self.invalidateIntrinsicContentSize()
        self.setEventHandler(for: .touchUpInside, action: viewModel.onTap)
        self.updateTitle(viewModel.title)
        self.updateColors()
    }
    
    private var currentBackgroundColor: ThemedColor {
        if isHighlighted || isSelected {
            return self.appearance.backgroundColorHighlighted
        }
        return self.appearance.backgroundColor
    }
    
    private var currentTintColor: ThemedColor {
        if isHighlighted || isSelected {
            return self.appearance.tintColorHighlighted
        }
        return self.appearance.tintColor
    }
    
    private func updateTitle(_ title: String? = nil) {
        let title = title ?? self.titleLabel?.attributedText?.string ?? ""
        let builder = AttributedStringBuilder(string: title)
            .font(self.appearance.titleFont)
            .foregroundColor(self.appearance.titleColor)
            .lineBreakMode(.byClipping)
            .alignment(.center)
        
        self.setAttributedTitle(builder.string(), for: .normal)
        
        let highlightedTitle = builder
            .foregroundColor(self.appearance.titleColorHighlighted)
            .string()
        
        self.setAttributedTitle(highlightedTitle, for: .highlighted)
        self.setAttributedTitle(highlightedTitle, for: .selected)
    }
    
    private func updateColors() {
        self.backgroundColorThemed = self.currentBackgroundColor
        self.tintColorThemed = self.currentTintColor
    }
    
    private func setup() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 6
        self.backgroundColorThemed = Palette.shared.gray5
        self.adjustsImageWhenHighlighted = false
    }
}

final class TaskAccessoryHeaderView: UIView {
    private lazy var titleLabel = UILabel()

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .trailing
        stackView.spacing = 5
        stackView.snp.makeConstraints {
            $0.height.equalTo(32)
        }
        return stackView
    }()
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 59)
    }
    
    func update(with viewModel: TaskAccessoryHeaderViewModel) {
		typealias ViewModel = TaskAccessoryHeaderViewModel
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .foregroundColor(Palette.shared.gray0)
            .primeFont(ofSize: 18, weight: .bold, lineHeight: 21.6)
            .string()
        
        self.buttonsStackView.removeArrangedSubviews()
		let mapper = { (model: ViewModel.Button) -> TaskAccessoryButton in
			let button = TaskAccessoryButton()
			button.update(
				with: .init(
					title: model.title,
					imageName: model.imageName,
					onTap: model.onTap
				)
			)
			button.addShadow(height: 1, opacity: 0.35)
			return button
		}
		
		let existingButton = mapper(viewModel.existingButton)
		let newButton = mapper(viewModel.newButton)
		
		if viewModel.selected == .existing {
			existingButton.isSelected = true
		} else if viewModel.selected == .new {
			newButton.isSelected = true
		}
		
        self.buttonsStackView.addArrangedSubview(existingButton)
        self.buttonsStackView.addArrangedSubview(newButton)
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TaskAccessoryHeaderView: Designable {
    func setupView() {
		self.backgroundColorThemed = Palette.shared.clear
		self.titleLabel.adjustsFontSizeToFitWidth = true
		self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
		self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func addSubviews() {
    }

    func makeConstraints() {
		let hStack = UIStackView.horizontal(
			self.titleLabel,
			.hSpacer(growable: 10),
			self.buttonsStackView
		)

		self.addSubviews(hStack)
		hStack.make(.edges, .equalToSuperview, [16, 10, -11, -10])
		self.titleLabel.make(.centerY, .equalToSuperview)
    }
}
// swiftlint:enable trailing_whitespace
