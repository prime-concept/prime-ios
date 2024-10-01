import UIKit

final class HotelGuestsSectionHeaderView: UIView {
    private lazy var titleLabel = UILabel()
    
    override init(frame: CGRect = .zero) {
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(title: String) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(title)
    }
}

extension HotelGuestsSectionHeaderView: Designable {
    func addSubviews() {
        self.addSubview(self.titleLabel)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(30)
            make.leading.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, lineHeight: 14)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }
}

