import UIKit

extension DetailRequestCreationSelectionView {
    struct Appearance: Codable {
        var mainFont = Palette.shared.primeFont.with(size: 15)
        var mainColor = Palette.shared.mainBlack

        var secondaryFont = Palette.shared.primeFont.with(size: 12)
        var secondaryColor = Palette.shared.gray1

        var separatorColor = Palette.shared.gray3
        var arrowTint = Palette.shared.gray1
    }
}

final class DetailRequestCreationSelectionView: UIView, TaskFieldValueInputProtocol {
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.mainFont
        label.textColorThemed = self.appearance.mainColor
        return label
    }()

    private lazy var secondaryLabel: UILabel = {
        let label = UILabel()
        label.fontThemed = self.appearance.secondaryFont
        label.textColorThemed = self.appearance.secondaryColor
        return label
    }()

    private lazy var separatorView: UIView = {
        let view = OnePixelHeightView()
        view.backgroundColorThemed = self.appearance.separatorColor
        return view
    }()

    private lazy var arrowIconImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(named: "calendar-header-right-icon")?.withRenderingMode(.alwaysTemplate)
        )
        imageView.tintColorThemed = self.appearance.arrowTint
        return imageView
    }()

    private let appearance: Appearance

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 65)
    }

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	// swiftlint:disable all
    func setup(with viewModel: TaskCreationFieldViewModel) {
        var value = ""
        switch viewModel.form.type {
			case .airport, .city, .partner:
            value = viewModel.input.newValue
        default:
            let selectedOptions = viewModel.input.dictionaryOptions.compactMap { selectedValue in
                viewModel.form.options.first(where: {
                    selectedValue == $0.value
                })?.name
            }
            value = selectedOptions.joined(separator: ",")
        }

		self.secondaryLabel.isHidden = value.isEmpty

        if value.isEmpty {
            self.mainLabel.text = viewModel.title
        } else {
            self.secondaryLabel.text = viewModel.title
            self.mainLabel.text = value
        }

        viewModel.onValidate = { [weak self] isValid, customMessage in
            self?.secondaryLabel.textColorThemed = isValid ? Palette.shared.gray1 : Palette.shared.danger
            self?.separatorView.backgroundColorThemed = isValid ? Palette.shared.gray3 : Palette.shared.danger

            let invalidStateTitle = customMessage ?? Localization.localize("detailRequestCreation.fillInTheField")
			let text = isValid ? viewModel.title : invalidStateTitle
            self?.secondaryLabel.text = text
			self?.secondaryLabel.isHidden = text.isEmpty
        }
    }
	// swiftlint:enable all
}

extension DetailRequestCreationSelectionView: Designable {
    func setupView() {
		self.translatesAutoresizingMaskIntoConstraints = false
    }

    func addSubviews() {
		self.make(.height, .equal, 65)

		let hStack = UIStackView(.horizontal)
		hStack.alignment = .center
		hStack.spacing = 5
		self.addSubview(hStack)
		hStack.make(.hEdges + .centerY, .equalToSuperview, [15, -20, 0])

		let vStack = UIStackView(.vertical)
		vStack.spacing = 5
		vStack.alignment = .leading

		vStack.addArrangedSubviews(
			self.secondaryLabel,
			self.mainLabel
		)

		let arrowContainer = UIView()
		arrowContainer.addSubview(self.arrowIconImageView)
		self.arrowIconImageView.make(.hEdges + .centerY, .equalToSuperview)
		self.arrowIconImageView.make(.size, .equal, [5.5, 10])

		hStack.addArrangedSubviews(vStack, arrowContainer)

		self.addSubview(self.separatorView)
		self.separatorView.make(.bottom, .equalToSuperview)
		self.separatorView.make(.hEdges, .equal, to: hStack)
    }

    func makeConstraints() {}
}
