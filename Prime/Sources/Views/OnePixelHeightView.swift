import UIKit

class OnePixelHeightView: UIView {
    static let height: CGFloat = 1 / UIScreen.main.scale

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.snp.makeConstraints { make in
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
