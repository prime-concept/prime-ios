import Foundation
import UIKit

struct AviaDatePickerModel {
    var title: String?
    let placeholder: String
}

extension AviaDatePickerFieldView {
    struct Appearance: Codable {
        var titleTextColor = Palette.shared.gray0
        var placeholderTextColor = Palette.shared.gray1
    }
}

class AviaDatePickerFieldView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var calendarImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "avia_calendar"))
        view.contentMode = .scaleAspectFit
		view.tintColorThemed = Palette.shared.brandSecondary
        return view
    }()

    private lazy var containerView = UIView()
    private let appearance: Appearance
    private let dateType: DateType

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance(), dateType: DateType) {
        self.appearance = appearance
        self.dateType = dateType
        super.init(frame: .zero)
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: AviaDatePickerModel) {
        let title = viewModel.title
        let placeholder = viewModel.placeholder
        let text = title^.isEmpty ? self.makePlaceholder(placeholder) : self.makeTitle(title^)
        self.titleLabel.attributedTextThemed = text
    }

    private func makePlaceholder(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 14, lineHeight: 17)
            .foregroundColor(self.appearance.placeholderTextColor)
            .string()
    }

    private func makeTitle(_ text: String) -> NSAttributedString {
        text.attributed()
            .primeFont(ofSize: 14, lineHeight: 17)
            .foregroundColor(self.appearance.titleTextColor)
            .string()
    }
}

extension AviaDatePickerFieldView: Designable {
    func addSubviews() {
        self.addSubview(self.containerView)
        self.containerView.addSubview(self.titleLabel)

        if !(dateType == .return) {
            self.calendarImageView.image = dateType.image
            self.containerView.addSubview(self.calendarImageView)
        }
    }

    func makeConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.bottom.equalToSuperview()
        }

        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        self.imageConstraint(isHidden: dateType == .return)
    }

    private func imageConstraint(isHidden: Bool) {
        if isHidden {
            self.titleLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(10)
            }
        } else {
            self.calendarImageView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 20, height: 20))
                make.leading.equalToSuperview()
            }
            self.titleLabel.snp.makeConstraints { make in
                make.leading.equalTo(self.calendarImageView.snp.trailing).offset(10)
            }
        }
    }
}

enum DateType: String {
    case single, departure, `return`

    var image: UIImage? {
        switch self {
        case .single, .departure:
            return UIImage(named: "avia_calendar")
        case .return:
            return nil
        }
    }
}
