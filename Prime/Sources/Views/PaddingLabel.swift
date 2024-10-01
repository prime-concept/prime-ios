import UIKit

final class PaddingLabel: UILabel {
    private var topInset: CGFloat
    private var bottomInset: CGFloat
    private var leftInset: CGFloat
    private var rightInset: CGFloat

    init(
        topInset: CGFloat = 0,
        bottomInset: CGFloat = 0,
        leftInset: CGFloat = 0,
        rightInset: CGFloat = 0
    ) {
        self.topInset = topInset
        self.bottomInset = bottomInset
        self.leftInset = leftInset
        self.rightInset = rightInset
        super.init(frame: .zero)
    }

    init(insets: UIEdgeInsets = .zero) {
        self.topInset = insets.top
        self.bottomInset = insets.bottom
        self.leftInset = insets.left
        self.rightInset = insets.right
        super.init(frame: .zero)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(
            top: self.topInset,
            left: self.leftInset,
            bottom: self.bottomInset,
            right: self.rightInset
        )
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + self.leftInset + self.rightInset,
            height: size.height + self.topInset + self.bottomInset
        )
    }
}
