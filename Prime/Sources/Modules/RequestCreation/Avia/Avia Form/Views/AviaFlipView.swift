import UIKit

struct AviaFlipModel {
    let departure: String
    let arrival: String
}

extension AviaFlipView {
    struct Appearance: Codable {
        var tintColor = Palette.shared.brandSecondary
    }
}

class AviaFlipView: UIView {
    private lazy var topLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        return label
    }()
    private lazy var bottomLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        return label
    }()
    private lazy var flipImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "flip_icon"))
        view.contentMode = .scaleAspectFit
        view.tintColorThemed = self.appearance.tintColor
        return view
    }()

    private var model: AviaFlipModel?
    private lazy var containerView = UIView()
    private let appearance: Appearance

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with model: AviaFlipModel) {
        self.model = model

        self.topLabel.attributedTextThemed = Self.makeValue(model.departure)
        self.bottomLabel.attributedTextThemed = Self.makeValue(model.arrival)
    }
}

extension AviaFlipView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.topLabel,
            self.bottomLabel,
            self.flipImageView
        ].forEach(self.containerView.addSubview)
    }

    func makeConstraints() {
        self.topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(self.flipImageView.snp.top).offset(-10)
            make.width.greaterThanOrEqualTo(25)
        }
        self.bottomLabel.snp.makeConstraints { make in
            make.top.equalTo(self.flipImageView.snp.bottom).offset(12)
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.equalToSuperview().offset(-12 )
            make.width.greaterThanOrEqualTo(25)
			make.width.equalTo(self.topLabel)
        }
        self.flipImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.trailing.equalToSuperview().offset(4)
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
        self.containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private static func makeValue(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 11, lineHeight: 13.2)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }
}
