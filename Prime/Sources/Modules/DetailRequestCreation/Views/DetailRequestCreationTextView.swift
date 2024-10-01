import UIKit

extension DetailRequestCreationTextView {
    struct Appearance: Codable {
        var titleFont = Palette.shared.primeFont.with(size: 12)
        var titleColor = Palette.shared.gray1

        var textFont = Palette.shared.primeFont.with(size: 15)
        var textColor = Palette.shared.gray0

        var separatorColor = Palette.shared.gray3
		var errorColor = Palette.shared.danger
    }
}

final class DetailRequestCreationTextView: UIView, TaskFieldValueInputProtocol {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.titleFont
        label.textColorThemed = self.appearance.titleColor
        return label
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.fontThemed = self.appearance.textFont
        textView.textColorThemed = self.appearance.textColor
        textView.isScrollEnabled = false
        textView.backgroundColorThemed = Palette.shared.clear
        return textView
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private let appearance: Appearance

    private var placeholder: String? {
        didSet {
            // swiftlint:disable:next prime_font
            self.titleLabel.text = self.placeholder
        }
    }

    private var text: String? {
        didSet {
            // swiftlint:disable:next prime_font
            self.textView.text = text
            (self.text ?? "").isEmpty ? self.hideTitle() : self.showTitle()
        }
    }

    var onTextEdit: ((String?) -> Void)?

    override var intrinsicContentSize: CGSize {
        let height: CGFloat = self.titleLabel.isHidden ? 65 : 130
        let size = CGSize(width: UIView.noIntrinsicMetric, height: height)
        return size
    }

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

    private func showTitle() {
        self.titleLabel.isHidden = false

        self.textView.snp.remakeConstraints { make in
            make.bottom.equalTo(self.separatorView.snp.top).offset(5)
            make.leading.trailing.equalToSuperview().inset(11)
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.height.equalTo(90)
        }
        self.invalidateIntrinsicContentSize()
    }

    private func hideTitle() {
        self.titleLabel.isHidden = true

        self.textView.snp.remakeConstraints { make in
            make.bottom.equalTo(self.separatorView.snp.top).offset(5)
            make.leading.trailing.equalToSuperview().inset(11)
            make.top.equalToSuperview().offset(22.5)
        }

        // swiftlint:disable:next prime_font
        self.textView.text = self.placeholder
        self.invalidateIntrinsicContentSize()
    }

    func setup(with viewModel: TaskCreationFieldViewModel) {
        self.placeholder = viewModel.title
        // swiftlint:disable:next prime_font
        self.text = viewModel.input.newValue

		viewModel.onValidate = { [weak self] isValid, customMessage in
			guard let self = self else {
				return
			}
			let invalidStateTitle = customMessage ?? Localization.localize("detailRequestCreation.fillInTheField")
			let text = isValid ? viewModel.title : invalidStateTitle
			self.titleLabel.textColorThemed = isValid ? self.appearance.titleColor : self.appearance.errorColor
			self.separatorView.backgroundColorThemed = isValid ? self.appearance.separatorColor : self.appearance.errorColor

			self.titleLabel.text = text
			self.titleLabel.isHidden = text.isEmpty
		}
    }
}

extension DetailRequestCreationTextView: Designable {
    func setupView() {
    }

    func addSubviews() {
        [self.titleLabel, self.textView, self.separatorView].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14.5)
            make.leading.trailing.equalToSuperview().inset(15)
        }
    }
}

extension DetailRequestCreationTextView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }

        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.text.isEmpty ? self.hideTitle() : self.showTitle()
        if textView.text.isEmpty == false {
            self.onTextEdit?(textView.text)
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text.isEmpty ? self.hideTitle() : self.showTitle()
        if textView.text == self.placeholder {
            // swiftlint:disable:next prime_font
            textView.text = ""
        }
    }
}
