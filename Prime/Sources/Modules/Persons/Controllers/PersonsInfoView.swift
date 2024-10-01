import Foundation
import UIKit

extension PersonsInfoView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.clear
        var roundedCutHeaderCornerRadius: CGFloat = 10
        var roundedCutHeaderArcRadius: CGFloat = 12.5
        var customBackgroundViewColor = Palette.shared.gray5
        var countTextColor = Palette.shared.brandSecondary
        var countChevronColor = Palette.shared.brandSecondary
        var separatorBackgroundColor = Palette.shared.gray3
        var titleTextColor = Palette.shared.gray0

        var addButtonBackgroundColor = Palette.shared.brandPrimary
        var addButtonTintColor = Palette.shared.gray5
        var addButtonCornerRadius: CGFloat = 10
        var addButtonBorderColor = Palette.shared.gray5
        var addButtonBorderWidth: CGFloat = 0
        

        var contentContainerBackgroundColor = Palette.shared.gray5
        var contentContainerCornerRadius: CGFloat = 10
        var contentContainerShadowOffset = CGSize(width: 0, height: 5)
        var contentContainerShadowRadius: CGFloat = 15
        var contentContainerShadowColor = Palette.shared.black
		var contentContainerShadowOpacity: Float = 0.1
    }
}

final class PersonsInfoView: UIView {
    private lazy var titleLabel = UILabel()
    private lazy var countLabel = UILabel()
    private lazy var countContainerView = UIView()
    private lazy var arrowImageView: UIImageView = {
        let arrowImage = UIImage(named: "arrow_right")
        let imageView = UIImageView(image: arrowImage)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColorThemed = self.appearance.countChevronColor
        return imageView
    }()

    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.backgroundColorThemed = self.appearance.contentContainerBackgroundColor
        view.layer.cornerRadius = self.appearance.contentContainerCornerRadius
        view.dropShadow(
            offset: self.appearance.contentContainerShadowOffset,
            radius: self.appearance.contentContainerShadowRadius,
            color: self.appearance.contentContainerShadowColor,
            opacity: self.appearance.contentContainerShadowOpacity
        )
        return view
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.setImage(
            UIImage(named: "plus_icon")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.tintColorThemed = self.appearance.addButtonTintColor
        button.backgroundColorThemed = self.appearance.addButtonBackgroundColor
        button.layer.borderColorThemed = self.appearance.addButtonBorderColor
        button.layer.borderWidth = self.appearance.addButtonBorderWidth
        button.layer.cornerRadius = self.appearance.addButtonCornerRadius
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.backgroundColorThemed = Palette.shared.clear
        return stackView
    }()

    private let appearance: Appearance

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Theme.shared.appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ProfilePersonalInfoCellViewModel) {
        self.isHidden = false
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 18, weight: .bold, lineHeight: 21.6)
            .string()
        self.countLabel.attributedTextThemed = "\(viewModel.count)".attributed()
            .foregroundColor(self.appearance.countTextColor)
            .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
            .string()
        self.countLabel.setContentHuggingPriority(.required, for: .horizontal)

        self.stackView.removeArrangedSubviews()
        let addNewInfoHandler: () -> Void = { [weak self] in
            let controller = ProfileAddNewPickerFactory.make(
                for: viewModel.supportedItemNames,
                title: nil,
                onSelect: { idx in
                    viewModel.openDetailsOnTabWithIndex(idx, true)
                }
            )
            self?.viewController?.present(controller, animated: true) {
                switch viewModel.title {
                case "profile.documents".localized:
                    AnalyticsEvents.Profile.tappedPlusButton(.documents).send()
                case "profile.contacts".localized:
                    AnalyticsEvents.Profile.tappedPlusButton(.contacts).send()
                default:
                    break
                }
            }
        }
        
        self.addButton.setEventHandler(for: .touchUpInside, action: addNewInfoHandler)
        self.countContainerView.addTapHandler {
            viewModel.onCountTap?()
        }
            
        for i in 0..<viewModel.items.count {
            let item = viewModel.items[i]
            let itemView: UIView

            switch item.content {
                case .plain(_):
                    itemView = self.makePlainInfoView(with: item)
                    itemView.addTapHandler {
                        viewModel.openDetailsOnTabWithIndex(i, false)
                }
                case .empty(let title, let subtitle):
                    itemView = self.makeEmptyInfoView(with: title, subtitle: subtitle)
                default:
                    return
            }
            if i > 0 {
                self.placeSeparator(on: itemView)
            }

            self.stackView.addArrangedSubview(itemView)
        }
    }
    
    private func placeSeparator(on view: UIView) {
        let separator = UIView()
        separator.backgroundColorThemed = self.appearance.separatorBackgroundColor
        view.addSubview(separator)

        separator.snp.remakeConstraints { make in
            make.width.equalTo(1 / UIScreen.main.scale)
            make.height.equalTo(55)
            make.centerY.leading.equalToSuperview()
        }
    }
    
    private func makePlainInfoView(with item: ProfilePersonalInfoCellViewModel.Item) -> PlainInfoView2 {
        guard case .plain(let image) = item.content else {
			fatalError("\(Self.self) \(#function) .plain(let image) != item.content")
        }

        let view = PlainInfoView2()
        let title = item.title.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .alignment(.center)
            .string()
        let attributedCount = " \(item.count)".attributed()
            .foregroundColor(self.appearance.countTextColor)
            .alignment(.left)
            .primeFont(ofSize: 12, lineHeight: 16)
            .string()

        view.label.attributedTextThemed = title + attributedCount
        view.imageView.image = image

        return view
    }

    private func makeEmptyInfoView(with title: String, subtitle: String) -> EmptyPersonsInfoView {
        let view = EmptyPersonsInfoView()
        view.titleLabel.attributedTextThemed = title.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 14, weight: .medium, lineHeight: 16.8)
            .string()
        view.subtitleLabel.attributedTextThemed = subtitle.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 11, lineHeight: 13)
            .string()

        return view
    }

}

extension PersonsInfoView: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.countContainerView.addSubview(self.countLabel)
        self.countContainerView.addSubview(self.arrowImageView)
        [
            self.titleLabel,
            self.countContainerView,
            self.addButton,
            self.contentContainerView
        ].forEach(self.addSubview)

        self.contentContainerView.addSubview(self.stackView)
    }

    func makeConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalTo(self.countContainerView.snp.leading).offset(-10)
            make.top.equalToSuperview()
        }

        self.countContainerView.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel).offset(-1.5)
            make.trailing.equalToSuperview().inset(22)
            make.height.equalTo(44)
        }

        self.arrowImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 14))
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        self.countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel)
            make.leading.equalToSuperview()
            make.trailing.equalTo(self.arrowImageView.snp.leading).offset(-2)
        }

        self.contentContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
            make.height.equalTo(75)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalTo(self.addButton.snp.leading).offset(15)
            make.bottom.equalToSuperview().inset(23)
        }

        self.addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(15)
            make.size.equalTo(CGSize(width: 60, height: 75))
            make.centerY.equalTo(self.contentContainerView)
        }

        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension EmptyPersonsInfoView {
	struct Appearance: Codable {
		var emptyViewBackgroundColor = Palette.shared.gray4
		var emptyViewCornerRadius: CGFloat = 8
	}
}

final class EmptyPersonsInfoView: UIView {
    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        super.init(frame: frame)

        self.placeSubviews()

        self.contentView.backgroundColorThemed = appearance.emptyViewBackgroundColor
        self.contentView.layer.cornerRadius = appearance.emptyViewCornerRadius
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var contentView = UIView()

    private(set) lazy var titleLabel = UILabel()
    private(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private func placeSubviews() {
        self.addSubview(self.contentView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subtitleLabel)

        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(3)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.leading.trailing.equalToSuperview().inset(11)
        }

        self.subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(11)
            make.bottom.equalToSuperview().offset(-11)
        }
    }
}

private final class PlainInfoView2: UIView {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.placeSubviews()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) lazy var imageView = with(UIImageView()) { imageView in
        imageView.contentMode = .scaleAspectFit
		imageView.tintColorThemed = Palette.shared.brandSecondary
    }

    private(set) lazy var label = with(UILabel()) { label in
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.lineBreakMode = .byTruncatingMiddle
    }

    private func placeSubviews() {
        self.addSubview(self.imageView)
        self.addSubview(self.label)

        self.imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 18, height: 28))
            make.centerX.equalToSuperview()
            make.top.equalTo(11)
        }

        self.label.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(13)
        }
    }
}
