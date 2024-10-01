import Foundation
import UIKit

struct AviaPassengerClassViewModel {
    let title: String
    var isSelected: Bool
    let onUpdate: (Bool) -> Void
}

class AviaPassengerClassView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var imageView: UIImageView = {
        var image = UIImageView(image: UIImage(named: "avia_check")?.withRenderingMode(.alwaysTemplate))
        image.tintColorThemed = Palette.shared.brandPrimary
        return image
    }()
    private lazy var separatorView = OnePixelHeightView()
    
    override init(frame: CGRect = .zero) {
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(viewModel: AviaPassengerClassViewModel) {
        self.titleLabel.attributedTextThemed = Self.makeTitle(viewModel.title)
        viewModel.isSelected ? (imageView.isHidden = false) : (imageView.isHidden = true)
        self.addTapHandler {
            viewModel.onUpdate(!viewModel.isSelected)
        }
    }
}

extension AviaPassengerClassView: Designable {
    func addSubviews() {
        [
            self.titleLabel,
            self.imageView,
            self.separatorView
        ].forEach(self.addSubview)
        self.separatorView.backgroundColorThemed = Palette.shared.gray3
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.leading.equalToSuperview().inset(15)
        }
        self.imageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(18)
        }
    }
    
    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 16, lineHeight: 18)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }
}
