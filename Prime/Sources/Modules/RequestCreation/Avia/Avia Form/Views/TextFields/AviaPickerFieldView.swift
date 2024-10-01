import SnapKit
import UIKit

struct AirportPickerViewModel {
    var value: String?
    var costValue: String?
    let placeholder: String
}

extension AviaPickerFieldView {
    struct Appearance: Codable {
        var placeholderColor = Palette.shared.gray1
        var valueColor = Palette.shared.gray0
        var separatorColor = Palette.shared.gray4
    }
}

final class AviaPickerFieldView: UIView {
    private lazy var label = UILabel()
    private lazy var separatorView = OnePixelHeightView()

    private lazy var pointImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "avia_point"))
        view.contentMode = .scaleAspectFit
		view.tintColorThemed = Palette.shared.brandSecondary
        return view
    }()
    
    private lazy var titlesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private lazy var rightSideLabel = {
        let label = UILabel()
        label.textColorThemed = Palette.shared.gray2
        label.fontThemed = Palette.shared.caption2Reg
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private var labelsStackTrailingConstraint: Constraint?
    private let appearance: Appearance

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with model: AirportPickerViewModel) {
        if let value = model.value {
            self.label.attributedTextThemed = value.attributed()
                .primeFont(ofSize: 14, lineHeight: 17)
                .foregroundColor(self.appearance.valueColor)
                .lineBreakMode(.byTruncatingTail)
                .string()
        } else {
            let placeholder = model.placeholder
            self.label.attributedTextThemed = placeholder.attributed()
                .primeFont(ofSize: 14, lineHeight: 17)
                .foregroundColor(self.appearance.placeholderColor)
                .string()
        }
        
        self.rightSideLabel.text = model.costValue ?? ""
        self.titlesStackView.addArrangedSubviews([self.label, self.rightSideLabel])
    }

    func updateLabelsStackTrailing(_ offset: ConstraintOffsetTarget) {
        self.labelsStackTrailingConstraint?.update(offset: offset)
    }
}

extension AviaPickerFieldView: Designable {
    func setupView() {
        self.label.numberOfLines = 1
        self.separatorView.backgroundColorThemed = self.appearance.separatorColor
    }

    func addSubviews() {
        [
            self.titlesStackView,
            self.pointImageView,
            self.separatorView
        ].forEach(self.addSubview)
    }

    func makeConstraints() {
        self.pointImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.leading.equalToSuperview().offset(15)
        }

        self.titlesStackView.snp.makeConstraints { make in
            make.centerY.equalTo(self.pointImageView)
            make.leading.equalTo(self.pointImageView.snp.trailing).offset(10)
            self.labelsStackTrailingConstraint = make.trailing.equalToSuperview().offset(-25).constraint
        }

        self.separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
        }
    }
}
