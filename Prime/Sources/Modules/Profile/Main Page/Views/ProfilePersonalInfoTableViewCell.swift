import UIKit

extension ProfilePersonalInfoTableViewCell {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray5
        var countTextColor = Palette.shared.brandSecondary
		var countChevronColor = Palette.shared.brandSecondary
        var separatorBackgroundColor = Palette.shared.gray3
        var titleTextColor = Palette.shared.gray0
        var expandTintColor = Palette.shared.brandSecondary
		var tintColor = Palette.shared.brandSecondary

        var contentContainerBackgroundColor = Palette.shared.gray5
        var contentContainerCornerRadius: CGFloat = 10
        var contentContainerShadowOffset = CGSize(width: 0, height: 5)
        var contentContainerShadowRadius: CGFloat = 15
        var contentContainerShadowColor = Palette.shared.black
		var contentContainerShadowOpacity: Float = 0.1
    }
}

final class ProfilePersonalInfoTableViewCell: UITableViewCell, Reusable {
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
        view.layer.borderWidth = 0.5
        view.layer.borderColorThemed = self.appearance.separatorBackgroundColor
        view.layer.cornerRadius = self.appearance.contentContainerCornerRadius
        view.dropShadow(
            offset: self.appearance.contentContainerShadowOffset,
            radius: self.appearance.contentContainerShadowRadius,
            color: self.appearance.contentContainerShadowColor,
            opacity: self.appearance.contentContainerShadowOpacity
        )
        return view
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.appearance = Theme.shared.appearance()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with viewModel: ProfilePersonalInfoCellViewModel) {
        self.titleLabel.attributedTextThemed = viewModel.title.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 18, weight: .bold, lineHeight: 21.6)
            .string()
        
        if viewModel.count.isEmpty == false {
            self.countLabel.attributedTextThemed = String(viewModel.count).attributed()
                .foregroundColor(self.appearance.countTextColor)
                .primeFont(ofSize: 16, weight: .medium, lineHeight: 20)
                .string()
        } else {
            self.arrowImageView.isHidden = true
        }

		self.stackView.removeArrangedSubviews()

		let addNewInfoHandler: () -> Void = { [weak self] in
			if viewModel.supportedItemNames.count == 1 {
				viewModel.openDetailsOnTabWithIndex(0, true)
                AnalyticsEvents.Profile.tappedPlusButton(.cards).send()
				return
			}
			
            if viewModel.supportedItemNames.isEmpty {
                viewModel.openDetailsOnTabWithIndex(0, true)
                return
            }
    
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

        if let handler = viewModel.onCountTap {
            self.countContainerView.addTapHandler(handler)
        }

		for i in 0..<viewModel.items.count {
			let item = viewModel.items[i]
			let itemView: UIView

			switch item.content {
				case .plain(_):
					itemView = self.makePersonPlainInfoView(with: item)
					itemView.addTapHandler {
						viewModel.openDetailsOnTabWithIndex(i, false)
					}
				case .empty(let title, let subtitle):
					itemView = self.makeProfilePersonInfoEmptyInfoView(with: title, subtitle: subtitle)
					itemView.addTapHandler(addNewInfoHandler)
				case .cards(_, _):
					itemView = self.makeCardsInfoView(with: item)
					itemView.addTapHandler {
						viewModel.openDetailsOnTabWithIndex(i, false)
					}
            case .family(_):
                itemView = self.makeFamilyInfoView(with: item)
                itemView.addTapHandler {
                    viewModel.openDetailsOnTabWithIndex(i, false)
                }
			}

			if i > 0 {
				self.placeSeparator(on: itemView)
			}

			self.stackView.addArrangedSubview(itemView)
		}
    }

    // MARK: - Helpers
	private func makePersonPlainInfoView(with item: ProfilePersonalInfoCellViewModel.Item) -> PersonPlainInfoView {
		guard case .plain(let image) = item.content else {
			fatalError("\(Self.self) \(#function) .plain(let image) != item.content")
		}

		let view = PersonPlainInfoView()
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
		view.label.numberOfLines = 0
		view.label.lineBreakMode = .byWordWrapping
		view.label.sizeToFit()

        view.imageView.image = image?.withRenderingMode(.alwaysTemplate)
        view.imageView.tintColorThemed = self.appearance.expandTintColor
		return view
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

    private func makeFamilyInfoView(with item: ProfilePersonalInfoCellViewModel.Item) -> FamilyPersonPlainInfoView {
        guard case .family(let image) = item.content else {
            fatalError("\(Self.self) \(#function) .plain(let image) != item.content")
        }

        let view = FamilyPersonPlainInfoView()
        view.label.attributedTextThemed = item.title.attributed()
            .foregroundColor(self.appearance.titleTextColor)
            .primeFont(ofSize: 12, lineHeight: 16)
            .alignment(.center)
            .string()

        view.imageView.image = image

        return view
    }
    
	private func makeProfilePersonInfoEmptyInfoView(with title: String, subtitle: String) -> ProfilePersonInfoEmptyInfoView {
		let view = ProfilePersonInfoEmptyInfoView()
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

	private func makeCardsInfoView(with item: ProfilePersonalInfoCellViewModel.Item) -> CardsInfoView {
		guard case .cards(let imageURLs, let colors) = item.content else {
			fatalError("\(Self.self) \(#function) .cards(let imageURLs, let colors) != item.content")
		}

		guard imageURLs.count == colors.count else {
			fatalError("\(Self.self) \(#function) imageURLs.count != colors.count")
		}

		let view = CardsInfoView()
		view.update(with: imageURLs, colors: colors)

		let title = item.title.attributed()
			.foregroundColor(self.appearance.titleTextColor)
			.primeFont(ofSize: 12, lineHeight: 16)
			.alignment(.left)
			.string()

		let attributedCount = " \(item.count)".attributed()
			.foregroundColor(self.appearance.countTextColor)
			.alignment(.left)
			.primeFont(ofSize: 12, lineHeight: 16)
			.string()

		view.label.attributedTextThemed = title + attributedCount

		return view
	}
}

extension ProfilePersonalInfoTableViewCell: Designable {
    func setupView() {
        self.backgroundColorThemed = self.appearance.backgroundColor
        self.selectionStyle = .none
    }

    func addSubviews() {
        [
            self.titleLabel,
            self.countContainerView,
			self.contentContainerView
        ].forEach(self.contentView.addSubview)

        self.contentContainerView.addSubview(self.stackView)

		self.countContainerView.addSubview(self.countLabel)
		self.countContainerView.addSubview(self.arrowImageView)
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
            make.trailing.equalToSuperview().inset(15)
			make.bottom.equalToSuperview().inset(23)
        }

        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

	func maskCell(fromTop margin: CGFloat) {
		self.layer.mask = self.visibilityMask(withLocation: margin / self.frame.size.height)
		self.layer.masksToBounds = true
	}

	private func visibilityMask(withLocation location: CGFloat) -> CAGradientLayer {
		let mask = CAGradientLayer()
		mask.frame = self.bounds
		mask.colorsThemed = [Palette.shared.gray5.withAlphaComponent(0), Palette.shared.gray5]
		let num = location as NSNumber
		mask.locations = [num, num]
		return mask
	}
}

extension ProfilePersonInfoEmptyInfoView {
	struct Appearance: Codable {
		var emptyViewBackgroundColor = Palette.shared.gray4
		var emptyViewCornerRadius: CGFloat = 8
	}
}

final class ProfilePersonInfoEmptyInfoView: UIView {
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

private final class PersonPlainInfoView: UIView {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
		self.placeSubviews()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private(set) lazy var imageView = with(UIImageView()) { imageView in
		imageView.contentMode = .center
	}

	private(set) lazy var label = with(UILabel()) { label in
		label.adjustsFontSizeToFitWidth = true
		label.minimumScaleFactor = 0.7
		label.lineBreakMode = .byWordWrapping
		label.numberOfLines = 0
	}

	private func placeSubviews() {
		let topSpacer = UIView()
		let bottomSpacer = UIView()

		self.addSubview(topSpacer)
		self.addSubview(self.imageView)
		self.addSubview(self.label)
		self.addSubview(bottomSpacer)

		topSpacer.make(.edges(except: .bottom), .equalToSuperview)
		self.imageView.make(.top, .equal, to: .bottom, of: topSpacer)
		self.imageView.make(.size, .equal, [18, 28])
		self.imageView.make(.centerX, .equalToSuperview)

		self.label.make(.top, .equal, to: .bottom, of: self.imageView, +7)
		self.label.make(.hEdges, .equalToSuperview, [8, -8])
		self.label.make(.bottom, .equal, to: .top, of: bottomSpacer)

		bottomSpacer.make(.edges(except: .top), .equalToSuperview)
		topSpacer.make(.height, .equal, to: bottomSpacer, +2)
	}
}

private final class FamilyPersonPlainInfoView: UIView {
	private let appearance = ProfilePersonalInfoTableViewCell.Appearance()

	override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.placeSubviews()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	private(set) lazy var imageView = with(UIImageView()) { (imageView: UIImageView) in
        imageView.contentMode = .scaleAspectFit
		imageView.tintColorThemed = self.appearance.tintColor
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
            make.size.equalTo(CGSize(width: 36, height: 36))
            make.centerX.equalToSuperview()
            make.top.equalTo(11)
        }

        self.label.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(7)
        }
    }
}

private final class CardsInfoView: UIView {
	private lazy var fadeView = with(GradientView()) { view in
		view.isHorizontal = true
		view.colors = [Palette.shared.gray5.withAlphaComponent(0), Palette.shared.gray5]
		view.points = (start: CGPoint(x: 0.0, y: 0.5), end: CGPoint(x: 0.75, y: 0.5))
	}

	override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		self.clipsToBounds = true
		self.placeSubviews()
	}

	@available (*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update(with imageURLs: [String], colors: [UIColor]) {
		let maxImageCount = Int(UIScreen.main.bounds.width / (46 + 5)) + 1

		let imageURLs = Array(imageURLs.prefix(maxImageCount))
		let colors = Array(colors.prefix(maxImageCount))

		self.hStack.removeArrangedSubviews()
		for i in 0..<imageURLs.count {
			let imageURL = imageURLs[i]
			let imageView = self.makeImageView()
			self.hStack.addArrangedSubview(imageView)

			let isURL = imageURL.hasPrefix("http")
			if isURL, let imageURL = URL(string: imageURL) {
				imageView.loadImage(from: imageURL)
			} else {
				imageView.image = UIImage(named: imageURL)
			}

			imageView.backgroundColor = colors[i]
		}
	}

	private lazy var hStack = with(UIStackView(.horizontal)) { stack in
		stack.spacing = 5
		stack.layer.cornerRadius = 3
		stack.layer.masksToBounds = true
	}

	private(set) lazy var label = UILabel()

	private func placeSubviews() {
		self.addSubview(self.hStack)
		self.addSubview(self.label)
		self.addSubview(self.fadeView)

		self.hStack.snp.makeConstraints { make in
			make.top.equalToSuperview().inset(17)
			make.leading.equalToSuperview().inset(13)
		}

		self.label.snp.makeConstraints { make in
			make.leading.trailing.equalToSuperview().inset(13)
			make.top.equalTo(self.hStack.snp.bottom).offset(7)
		}

		self.fadeView.make(.trailing, .equalToSuperview)
		self.fadeView.make([.centerY, .height], .equal, to: self.hStack)
		self.fadeView.make(.width, .equal, 46)
	}

	private func makeImageView() -> UIImageView {
		let imageView = UIImageView()
		imageView.contentMode = .scaleAspectFit
		imageView.layer.masksToBounds = true
		imageView.layer.cornerRadius = 3
		imageView.snp.makeConstraints { make in
			make.size.equalTo(CGSize(width: 46, height: 28))
		}
		return imageView
	}
}
