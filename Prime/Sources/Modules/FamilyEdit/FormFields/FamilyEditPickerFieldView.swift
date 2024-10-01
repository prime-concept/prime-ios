import Foundation
import UIKit

struct FamilyEditPickerModel {
    let title: String
    let values: [String]
    let selectedIndex: Int?
    let pickerInvoker: () -> Void
}

extension FamilyEditPickerFieldView {
    struct Appearance: Codable {
        var neutralSeparatorColor = Palette.shared.gray3
        var activeSeparatorColor = Palette.shared.gray0
        var textColor = Palette.shared.gray0
        var titleTextColor = Palette.shared.gray1
    }
}

class FamilyEditPickerFieldView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var valueLabel = UILabel()
    private lazy var separatorView = OnePixelHeightView()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "small_arrow"))
        view.contentMode = .scaleAspectFit
        view.tintColorThemed = Palette.shared.gray1
        return view
    }()
    
    private var model: FamilyEditPickerModel?
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

    func setup(with model: FamilyEditPickerModel) {
        self.model = model
        self.titleLabel.attributedTextThemed = Self.makeTitle(model.title + "*")
        
        let value: String = {
            if let index = model.selectedIndex {
                return model.values[index]
            }
            return model.title
        }()
        self.valueLabel.attributedTextThemed = Self.makeValue(value, isEmpty: self.model?.selectedIndex == nil)

        self.containerView.addTapHandler {
            model.pickerInvoker()
        }
    }
}

extension FamilyEditPickerFieldView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        [
            self.valueLabel,
            self.titleLabel,
            self.arrowView,
            self.separatorView
        ].forEach(self.containerView.addSubview)
        self.valueLabel.numberOfLines = 1
        self.titleLabel.numberOfLines = 1
        
        self.separatorView.backgroundColorThemed = Palette.shared.gray3
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(15)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview()
        }
        self.valueLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview()
        }
        self.separatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.valueLabel.snp.bottom).offset(10)
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


    private static func makeValue(_ text: String, isEmpty: Bool) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 15, lineHeight: 20)
            .foregroundColor(Palette.shared.gray0.withAlphaComponent(isEmpty ? 0.3 : 1.0))
            .string()
    }
}
