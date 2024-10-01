import UIKit

struct CardEditPickerModel {
    let title: String
    let values: [String]
    let selectedIndex: Int?
    let pickerInvoker: () -> Void
}

extension CardEditPickerFieldView {
    struct Appearance: Codable {
        var neutralSeparatorColor = Palette.shared.gray3
        var activeSeparatorColor = Palette.shared.gray0
        var textColor = Palette.shared.gray0
        var titleTextColor = Palette.shared.gray1
    }
}

class CardEditPickerFieldView: UIView {
    private lazy var valueLabel = UILabel()
    private lazy var separatorView = OnePixelHeightView()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "small_arrow"))
        view.contentMode = .scaleAspectFit
        view.tintColorThemed = Palette.shared.gray1
        return view
    }()

    private var model: CardEditPickerModel?
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

    func setup(with model: CardEditPickerModel) {
        self.model = model

        let value: String = {
            if let index = model.selectedIndex {
                return model.values[index]
            }
            return model.title
        }()
        self.valueLabel.attributedTextThemed = Self.makeValue(value)

        self.containerView.addTapHandler {
            model.pickerInvoker()
        }
    }
    func set(type: String) {
        self.valueLabel.attributedTextThemed = type.attributed()
            .primeFont(ofSize: 15, lineHeight: 20)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }
}

extension CardEditPickerFieldView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.valueLabel,
            self.arrowView,
            self.separatorView
        ].forEach(self.containerView.addSubview)
        self.valueLabel.numberOfLines = 1

        self.separatorView.backgroundColorThemed = Palette.shared.gray3
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
        }

        self.valueLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(13)
            make.leading.equalToSuperview()
        }
        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.valueLabel.snp.bottom).offset(15)
        }

        self.arrowView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 10))
            make.leading.equalTo(self.valueLabel.snp.trailing).offset(15)
        }
    }
    private static func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 12, lineHeight: 15)
            .foregroundColor(Palette.shared.gray1)
            .string()
    }


    private static func makeValue(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 20)
            .foregroundColor(Palette.shared.gray0)
            .string()
    }
}
