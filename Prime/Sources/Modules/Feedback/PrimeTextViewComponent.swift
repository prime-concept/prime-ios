import UIKit

extension PrimeTextViewComponent {
    struct Appearance: Codable {
		var textFont = Palette.shared.body2
		var textColor = Palette.shared.gray0

		var titleFont = Palette.shared.captionReg
		var titleTextColor = Palette.shared.gray1

		var placeholderFont = Palette.shared.body2
		var placeholderTextColor = Palette.shared.gray1

		var neutralSeparatorColor = Palette.shared.gray3
		var activeSeparatorColor = Palette.shared.gray0
    }
}

class PrimeTextViewComponent: UIView {
	private lazy var titleLabel = UILabel { (label: UILabel) in
		label.fontThemed = self.appearance.titleFont
		label.textColorThemed = self.appearance.titleTextColor
	}

	private lazy var placeholderLabel = UILabel { (label: UILabel) in
		label.fontThemed = self.appearance.placeholderFont
		label.textColorThemed = self.appearance.placeholderTextColor
		label.addTapHandler { [weak self] in
			self?.textView.becomeFirstResponder()
		}
	}

	var placeholder: String {
		didSet {
			self.placeholderLabel.text = self.placeholder

			self.titleLabel.attributedTextThemed = self.placeholder
				.attributed()
				.foregroundColor(self.appearance.titleTextColor)
				.primeFont(ofSize: 12, lineHeight: 16)
				.string()

			self.updateTitle(isHidden: self.text.isEmpty)
		}
	}

	var text: String {
		didSet {
			self.textView.attributedTextThemed = self.text
				.attributed()
				.foregroundColor(self.appearance.textColor)
				.primeFont(ofSize: 15, lineHeight: 20)
				.string()

			self.updateTitle(isHidden: self.text.isEmpty)
		}
	}

	var numberOfLines: Int {
		didSet {
			self.textView.maxHeight = self.appearance.textFont.lineHeight * CGFloat(self.numberOfLines)
		}
	}

	private lazy var textView: MessageGrowingTextView = {
		let textView = MessageGrowingTextView()
		textView.fontThemed = self.appearance.textFont
		textView.lineHeight = self.appearance.textFont.lineHeight
		textView.textContainerInset = .zero
		textView.textContainer.lineFragmentPadding = 0
		textView.baselineOffset = 1.0
		textView.minHeight = self.appearance.textFont.lineHeight
		textView.maxHeight = self.appearance.textFont.lineHeight * CGFloat(self.numberOfLines)
		textView.autocorrectionType = .no
		textView.backgroundColor = .clear

        textView.textColorThemed = self.appearance.textColor
		textView.onTextChange = { [weak self] text in
			guard let self = self else { return }

			self.text = text
			self.onTextUpdate?(text)
		}

		textView.onTextBeginEditing = { [weak self] in
			guard let self = self else { return }
			self.updateTitle(isHidden: false)
		}

		textView.onTextEndEditing = { [weak self] in
			guard let self = self else { return }
			self.updateTitle(isHidden: self.text.isEmpty)
		}

		textView.fontThemed = self.appearance.textFont
        return textView
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.neutralSeparatorColor
        return view
    }()

    private lazy var containerView = UIView()
    private let appearance: Appearance

    var onTextUpdate: ((String) -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 55)
    }

	init(
		frame: CGRect = .zero,
		appearance: Appearance = Theme.shared.appearance(),
		text: String = "",
		placeholder: String = "",
		numberOfLines: Int = 0
	) {
        self.appearance = appearance

		self.text = text
		self.placeholder = placeholder
		self.numberOfLines = numberOfLines

        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    private func updateTitle(isHidden: Bool) {
		let isHidden = isHidden && !self.textView.isFirstResponder

		UIView.animate(withDuration: 0.1) {
			self.titleLabel.alpha = isHidden ? 0 : 1
			self.placeholderLabel.alpha = 1 - self.titleLabel.alpha
		}
    }
}

extension PrimeTextViewComponent: Designable {
    func setupView() {}

    func addSubviews() {
		self.addSubview(self.containerView)
		self.addSubview(self.placeholderLabel)

		self.containerView.addSubviews(
			self.titleLabel,
			self.textView,
			self.separatorView
		)
    }

    func makeConstraints() {
		self.containerView.make(.edges, .equalToSuperview)
		self.placeholderLabel.make(.edges, .equalToSuperview, [10, 0, -10, 0])
		self.titleLabel.make(.edges(except: .bottom), .equalToSuperview, [10, 0, 0])

		self.textView.place(under: self.titleLabel, +5)
		self.textView.make(.hEdges, .equalToSuperview)

		self.separatorView.place(under: self.textView, +10)
		self.separatorView.make(.edges(except: .top), .equalToSuperview)
    }
}
