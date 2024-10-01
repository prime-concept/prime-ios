import UIKit

fileprivate extension CGFloat {
    static let searchIconSideSize: CGFloat = 14
    static let contentPadding: CGFloat = 10
}

extension SearchTextField {
    struct Appearance: Codable {
        var placeholderFont = Palette.shared.primeFont.with(size: 14)
        var placeholderColor = Palette.shared.gray1

        var textFont = Palette.shared.primeFont.with(size: 14)
        var textColor = Palette.shared.mainBlack

        var backgroundColor = Palette.shared.gray5

        var borderColor = Palette.shared.gray3
        var borderWidth: CGFloat = 0.5
    }
}

final class SearchTextField: UITextField {
    private let appearance: Appearance
    private let placeholderText: String

    init(placeholder: String, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        self.placeholderText = placeholder
        super.init(frame: .zero)

        self.setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(
            x: 15,
            y: 11,
            width: .searchIconSideSize,
            height: .searchIconSideSize
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let leftPadding = .searchIconSideSize + .contentPadding + 13
        let rightPadding: CGFloat = .contentPadding

        return CGRect(
            x: leftPadding,
            y: 0,
            width: bounds.width - leftPadding - rightPadding,
            height: bounds.height
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    private func setUp() {
		attributedPlaceholder = self.placeholderText.attributed()
			.foregroundColor(self.appearance.placeholderColor)
			.font(self.appearance.placeholderFont)
			.string()
		
        fontThemed = self.appearance.textFont
        textColorThemed = self.appearance.textColor
        backgroundColorThemed = self.appearance.backgroundColor
        layer.borderWidth = self.appearance.borderWidth
        layer.borderColorThemed = self.appearance.borderColor
        self.updateLeftView()
    }

    private func updateLeftView() {
        leftView = UIImageView(image: UIImage(named: "search-icon"))
        leftView?.contentMode = .scaleAspectFit
        leftViewMode = .always
    }
}
