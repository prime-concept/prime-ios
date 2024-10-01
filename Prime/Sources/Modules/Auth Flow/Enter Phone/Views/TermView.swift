import UIKit

fileprivate class TermTextView: UITextView {
    override var canBecomeFirstResponder: Bool {
        false
    }
}

extension TermView {
    struct Appearance: Codable {
        var tintColor = Palette.shared.brandSecondary
        var linkTextColor = Palette.shared.brandSecondary
		var font = Palette.shared.primeFont.with(size: 12)
    }
}

final class TermView: UIView {
    private lazy var checkBoxView: UIView = {
        let view = UIImageView()
        view.image = UIImage(named: "checkbox_off")?.withRenderingMode(.alwaysTemplate)
        view.tintColorThemed = self.appearance.tintColor
        view.addTapHandler(feedback: .scale) { [weak self] in
            self?._isSelected.toggle()
            self?.onCheckBoxTap?()
        }
        return view.withExtendedTouchArea(insets: .init(top: 5, left: 50, bottom: 5, right: 5))
    }()

    private lazy var termsTextView = with(TermTextView()) { textView in
        textView.backgroundColorThemed = Palette.shared.clear
		textView.fontThemed = self.appearance.font
        textView.delegate = self
        textView.dataDetectorTypes = .link
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.linkTextAttributes = [.foregroundColor: self.appearance.linkTextColor]
    }

    private var _isSelected: Bool = false {
        willSet {
            guard let checkBoxImageView = self.checkBoxView.subviews.first as? UIImageView else {
                return
            }
            checkBoxImageView.image = newValue ? UIImage(named: "checkbox_on")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "checkbox_off")?.withRenderingMode(.alwaysTemplate)
            checkBoxImageView.tintColorThemed = self.appearance.tintColor
        }
    }

    var isSelected: Bool {
        self._isSelected
    }

    var onCheckBoxTap: (() -> Void)?
	var onLinkTap: ((URL) -> Void)?
    
    private let appearance: Appearance

    init(appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTerms(with text: NSAttributedString) {
        termsTextView.attributedTextThemed = text
    }
}

extension TermView: Designable {
    func addSubviews() {
        [
            self.termsTextView,
            self.checkBoxView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.checkBoxView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 34, height: 34))
			make.top.leading.equalToSuperview()
        }

        self.termsTextView.snp.makeConstraints { make in
            make.leading.equalTo(self.checkBoxView.snp.trailing).offset(-3)
            make.trailing.equalToSuperview()
			make.top.equalTo(self.checkBoxView).inset(8)
            make.bottom.greaterThanOrEqualToSuperview().offset(-10)
        }

		self.make(.height, .greaterThanOrEqual, 44)
    }
}

extension TermView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange
    ) -> Bool {
		self.onLinkTap?(url)
        return false
    }
}
