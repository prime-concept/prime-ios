import UIKit

extension RequestCreationButton {
	struct Appearance: Codable {
		var titleFont = Palette.shared.primeFont.with(size: 13, weight: .regular)
		var titleLeading: CGFloat = 36
		var titleTrailing: CGFloat = 10

		var backgroundColor = Palette.shared.gray5
		var backgroundColorHighlighted = Palette.shared.brandPrimary

		var tintColor = Palette.shared.brandPrimary
		var tintColorHighlighted = Palette.shared.gray5

		var titleColor = Palette.shared.gray0
		var titleColorHighlighted = Palette.shared.gray5
	}
}

// swiftlint:disable trailing_whitespace
class RequestCreationButton: UIButton {
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
    
    private func updateColors() {
        self.backgroundColorThemed = self.currentBackgroundColor
        self.tintColorThemed = self.currentTintColor
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(
			width: self.appearance.titleLeading + titleSize.width + self.appearance.titleTrailing,
            height: 42
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView?.center = CGPoint(
            x: self.appearance.titleLeading / 2,
            y: bounds.size.height / 2
        )
        
        self.titleLabel?.frame = CGRect(
            origin: CGPoint(x: self.appearance.titleLeading, y: 0),
            size: CGSize(width: titleSize.width, height: bounds.height)
        )
    }
    
    func update(with viewModel: RequestCreationCategoriesViewModel.Button) {
        let image = viewModel.image?.withRenderingMode(.alwaysTemplate)
        self.setImage(image, for: .normal)
        self.tag = viewModel.id
        self.updateTitle(with: viewModel.title)
        
        self.invalidateIntrinsicContentSize()
    }
    
    private func updateTitle(with string: String) {
        var attributedTitle = AttributedStringBuilder(string: string)
            .font(self.appearance.titleFont)
            .foregroundColor(self.appearance.titleColor)
        
        self.setAttributedTitle(attributedTitle.string(), for: .normal)
        
        attributedTitle = attributedTitle.foregroundColor(self.appearance.titleColorHighlighted)
        self.setAttributedTitle(attributedTitle.string(), for: .highlighted)
        self.setAttributedTitle(attributedTitle.string(), for: .selected)
    }
    
    private var titleSize: CGSize {
        guard let title = titleLabel?.text else {
            return .zero
        }
		var size = title.size(using: self.appearance.titleFont.rawValue)
		size.width += self.appearance.titleFont.rawValue.lineHeight / 2

		return size
    }
    
    private func setup() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 6
        self.adjustsImageWhenHighlighted = false
		self.tintColorThemed = self.currentTintColor
		self.backgroundColorThemed = self.currentBackgroundColor
    }
}

final class RequestCreationCategoriesSelectionView: UIView {
    private typealias Category = RequestCreationCategoriesViewModel.Button

    private lazy var topScrollView = UIScrollView()
    private lazy var bottomScrollView = UIScrollView()
    private lazy var topStackView = UIStackView()
    private lazy var bottomStackView = UIStackView()
    
    var onSelected: ((Int) -> Void)?
    
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
    
    func update(with viewModel: RequestCreationCategoriesViewModel) {
        self.topStackView.removeArrangedSubviews()
        self.bottomStackView.removeArrangedSubviews()
		var selectedButton: RequestCreationButton?

        let buttonMaker = { (category: Category) -> RequestCreationButton in
            let button = RequestCreationButton()
            button.update(with: category)
            button.setEventHandler(for: .touchUpInside) {
                viewModel.onCategorySelected(category.id)
            }
            button.addShadow(height: 1, opacity: 0.35)
            viewModel.selectedId.some {
                button.isSelected = category.id == $0
            }
			if button.isSelected {
				selectedButton = button
			}
            return button
        }
        viewModel.topRow.map(buttonMaker).forEach { button in
            self.topStackView.addArrangedSubview(button)
        }
        viewModel.bottomRow.map(buttonMaker).forEach { button in
            self.bottomStackView.addArrangedSubview(button)
        }
        
        self.topScrollView.isHidden = viewModel.topRow.isEmpty
        self.bottomScrollView.isHidden = viewModel.bottomRow.isEmpty

		self.scrollToSelectedButtonIfNeeded(selectedButton)
    }

	private func scrollToSelectedButtonIfNeeded(_ button: UIView?) {
        guard let button else { return }

		self.setNeedsLayout()
		self.layoutIfNeeded()

		let rect = button.frame

		if self.topStackView.subviews.contains(button) {
			self.topScrollView.scrollRectToVisible(rect, animated: true)
		}
		if self.bottomStackView.subviews.contains(button) {
			self.bottomScrollView.scrollRectToVisible(rect, animated: true)
		}
	}

    override var intrinsicContentSize: CGSize {
        //TODO: - replace magic numbers with explained.
        CGSize(width: UIView.noIntrinsicMetric, height: 43 + 10 + 43 + 1)
    }
}

extension RequestCreationCategoriesSelectionView: Designable {
    func setupView() {
        self.backgroundColorThemed = Palette.shared.clear
        [self.topStackView, self.bottomStackView].forEach { stack in
            stack.axis = .horizontal
            stack.alignment = .top
            stack.spacing = 6
        }
        [self.topScrollView, self.bottomScrollView].forEach { scroll in
            scroll.contentInset = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10)
            scroll.showsVerticalScrollIndicator = false
            scroll.showsHorizontalScrollIndicator = false
        }
    }

    func addSubviews() {
        self.topScrollView.addSubview(self.topStackView)
        self.bottomScrollView.addSubview(self.bottomStackView)
    }

    func makeConstraints() {
        [self.topStackView, self.bottomStackView].forEach { stack in
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalToSuperview()
                make.height.equalTo(43)
            }
        }
        
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 10
        self.addSubview(vStack)
        vStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        vStack.addArrangedSubview(self.topScrollView)
        vStack.addArrangedSubview(self.bottomScrollView)
    }
}
// swiftlint:enable trailing_whitespace
extension UIView {
    func addShadow(
        width: CGFloat = 0,
        height: CGFloat = 0,
		color: ThemedColor = Palette.shared.black,
        radius: CGFloat = 0,
        opacity: Float = 1
    ) {
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: width, height: height)
        layer.shadowColorThemed = color
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
		layer.backgroundColorThemed = self.backgroundColorThemed
    }
}
