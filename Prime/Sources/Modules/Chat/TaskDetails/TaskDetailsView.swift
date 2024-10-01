import UIKit
import MapKit

extension TaskDetailsView {
    struct Appearance: Codable {
        var backgroundColor = Palette.shared.gray4

        var sectionTitleFont = Palette.shared.primeFont.with(size: 18, weight: .bold)
        var sectionTitleColor = Palette.shared.gray0

        var sectionSubtitleFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
        var sectionSubtitleColor = Palette.shared.brandSecondary

        var rowNameColor = Palette.shared.gray1
        var rowNameFont = Palette.shared.primeFont.with(size: 14, weight: .regular)
        var rowValueColor = Palette.shared.gray0
        var rowValueFont = Palette.shared.primeFont.with(size: 14, weight: .regular)

        var separatorColor = Palette.shared.gray3

        var buttonTitleColor = Palette.shared.gray5
        var buttonBackgroundColor = Palette.shared.brandPrimary
        var buttonCornerRadius: CGFloat = 8
        var buttonFont = Palette.shared.primeFont.with(size: 16, weight: .medium)
    }
}

class TaskDetailsView: UIView {
    private let appearance: Appearance

    private lazy var contentStack = UIStackView(.vertical)
    private lazy var buttonHolder = UIView { buttonHolder in
        buttonHolder.addSubview(self.actionButton)
        self.actionButton.make(.edges, .equalToSuperview, [20, 15, -20, -15])
    }
    private var buttonTapHandler: (() -> Void)?

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(self.appearance.buttonTitleColor, for: .normal)
        button.titleLabel?.fontThemed = self.appearance.buttonFont
        button.backgroundColorThemed = self.appearance.buttonBackgroundColor
        button.layer.cornerRadius = self.appearance.buttonCornerRadius
        button.make(.height, .equal, 44)
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.buttonTapHandler?()
        }
        return button
    }()
    
    private var mapView: MapContainerView!

    init(frame: CGRect = .zero, appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        super.init(frame: frame)
        self.setupSubviews()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        self.backgroundColorThemed = self.appearance.backgroundColor

        let view = with(UIStackView(.vertical)) { mainStack in
            mainStack.addArrangedSubview(UIView { scrollableStackHolder in
                scrollableStackHolder.addSubview(with(ScrollableStack(.vertical)) { scrollableStack in
                    scrollableStack.contentInset.top = 20
                    scrollableStack.contentInset.bottom = 20
                    scrollableStack.addArrangedSubviews(
                        with(UIStackView(.horizontal)) { stack in
                            stack.addArrangedSubviews(.hSpacer(15), self.contentStack, .hSpacer(15))
                        }
                    )
                })
                scrollableStackHolder.subviews.first?.make(.edges, .equalToSuperview)
            })
            mainStack.addArrangedSubview(self.buttonHolder)
        }

        self.addSubview(view)
        view.make(.edges, .equal, to: self.safeAreaLayoutGuide)
    }

    private func makeMapView(long: Double, lat: Double, address: String?) -> UIView {
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        // Create a UIStackView with a vertical axis
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        // Create a MapContainerView instance
        mapView = MapContainerView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 100), location: location)
        mapView.layer.cornerRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.text = Localization.localize("profile.contacts")
        stackView.addArrangedSubview(.vSpacer(15))
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(.vSpacer(15))
        stackView.addArrangedSubview(mapView)
        
        let address = with(UILabel()) {
            $0.textColorThemed = self.appearance.sectionSubtitleColor
            $0.fontThemed = self.appearance.rowNameFont
            $0.textAlignment = .left
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.text = address
        }
        
        stackView.addArrangedSubview(.vSpacer(15))
        stackView.addArrangedSubview(address)
        
        addSubview(stackView)

        stackView.addTapHandler {
            self.openMap(location: location)
        }

        // Set constraints for the stack view to fill the TaskView
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 140)
        ])
        return stackView
    }

    func update(with viewModel: TaskDetailsViewModel) {
        self.contentStack.removeArrangedSubviews()

        for i in 0..<viewModel.sections.count {
            let sectionModel = viewModel.sections[i]
            let section = self.makeSection(with: sectionModel)
            self.contentStack.addArrangedSubview(section)
            if sectionModel.showSeparator {
                self.contentStack.addArrangedSubview(self.makeSeparator())
            }
        }

        self.actionButton.setTitle(viewModel.button?.title, for: .normal)
        self.buttonTapHandler = viewModel.button?.action
        self.buttonHolder.isHidden = viewModel.button == nil
    }

    private func makeSection(with viewModel: TaskDetailsViewModel.Section) -> UIView {
        let stack = UIStackView(.vertical)
        let header = self.makeSectionHeader(with: viewModel)
        stack.addArrangedSubview(header)
        if !(viewModel.haveToShowMap ?? false) {
            stack.addArrangedSubview(.vSpacer(15))
        }
        
        if let taskNumber = viewModel.taskNumber {
            let taskNumberView = makeTaskNumber(taskNumber)
            stack.addArrangedSubview(taskNumberView)
            stack.addArrangedSubview(.vSpacer(15))
        }
        
        if viewModel.haveToShowMap ?? false,
           let long = viewModel.longitude,
            let lat = viewModel.latitude {
            let map = makeMapView(long: long, lat: lat, address: viewModel.address)
            stack.addArrangedSubview(map)
            stack.addArrangedSubview(.vSpacer(15))
        }

        for i in 0..<viewModel.rows.count {
            let row = self.makeRow(with: viewModel.rows[i])
            stack.addArrangedSubview(row)

            if i < viewModel.rows.count - 1 {
                stack.addArrangedSubview(.vSpacer(15))
            }
        }

        return stack
    }

    private func makeSectionHeader(with viewModel: TaskDetailsViewModel.Section) -> UIView {
        let title = with(UILabel()) {
            $0.textColorThemed = self.appearance.sectionTitleColor
            $0.fontThemed = self.appearance.sectionTitleFont
            $0.textAlignment = .left
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.text = viewModel.title
        }

        let subtitle = with(UILabel()) {
            $0.textColorThemed = self.appearance.sectionSubtitleColor
            $0.fontThemed = self.appearance.sectionSubtitleFont
            $0.textAlignment = .left
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.text = viewModel.subtitle
        }

        let stackView = UIStackView(.horizontal)
        stackView.addArrangedSubviews(title, .hSpacer(20), subtitle)

        title.make(.width, .equal, to: subtitle)

        return stackView
    }

    private func makeRow(with viewModel: TaskDetailsViewModel.Section.Row) -> UIView {
        let nameLabel = with(UILabel()) {
            $0.attributedTextThemed = viewModel.name.attributed()
                .foregroundColor(self.appearance.rowNameColor)
                .font(self.appearance.rowNameFont)
                .alignment(.left)
                .lineHeightMultiplier(1.25)
                .lineBreakMode(.byWordWrapping)
                .string()
            $0.numberOfLines = 0
        }

        let valueTextView = with(UITextView()) {
            let builder = viewModel.value.attributed()
                .font(self.appearance.rowValueFont)
                .foregroundColor(self.appearance.rowValueColor)
                .backgroundColor(.clear)
                .alignment(.left)
                .lineBreakMode(.byWordWrapping)
                .lineHeightMultiplier(1.25)

            if let action = viewModel.action {
                $0.addTapHandler(action)
                builder[.underlineStyle] = NSUnderlineStyle.single.rawValue
                builder[.underlineColor] = self.appearance.rowValueColor
            }

            $0.isEditable = false
            $0.isSelectable = true
            $0.isScrollEnabled = false
            $0.dataDetectorTypes = .all
            $0.textAlignment = .left
            $0.attributedTextThemed = builder.string()
            $0.textContainerInset = .zero
            $0.textContainer.lineFragmentPadding = 0
            $0.textContainer.maximumNumberOfLines = 0
            $0.textContainer.lineBreakMode = .byWordWrapping
            $0.backgroundColor = .clear
            $0.linkTextAttributes[.foregroundColor] = self.appearance.rowValueColor
            $0.linkTextAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            $0.linkTextAttributes[.underlineColor] = self.appearance.rowValueColor
        }

        let nameStack = with(UIStackView(.vertical)) { stack in
            stack.addArrangedSubview(nameLabel)
            stack.addArrangedSubview(.vSpacer(growable: 0))
        }

        let valueStack = with(UIStackView(.vertical)) { stack in
            stack.addArrangedSubview(valueTextView)
            stack.addArrangedSubview(.vSpacer(growable: 0))
        }

        let stackView = UIStackView(.horizontal)
        stackView.addArrangedSubviews(nameStack, .hSpacer(20), valueStack)

        nameStack.make([.width, .height], .equal, to: valueStack)

        return stackView
    }
	
    private func makeSeparator() -> UIView {
        with(UIStackView(.vertical)) { stack in
            stack.addArrangedSubviews(
                .vSpacer(20),
                UIView {
                    $0.backgroundColorThemed = self.appearance.separatorColor
                    $0.make(.height, .equal, 1.0 / UIScreen.main.scale)
                },
                .vSpacer(20)
            )
        }
    }
    
    private func makeTaskNumber(_ taskNumberString: String) -> UIView {
        let title = with(UILabel()) {
            $0.textColorThemed = self.appearance.rowValueColor
            $0.fontThemed = self.appearance.sectionSubtitleFont
            $0.textAlignment = .left
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.text = taskNumberString
        }
        let stackView = UIStackView()
        stackView.addArrangedSubviews(title)
        return stackView
    }
    
    func openMap(location: CLLocationCoordinate2D?) {
        let mapVC = PartialMapViewController()
        mapVC.location = location
        present(mapVC)
    }
}

extension TaskDetailsView {
    private func present(_ viewController: UIViewController) {
        let router = ModalRouter(
            source: self.viewController,
            destination: viewController,
            modalPresentationStyle: .pageSheet
        )
        router.route()
    }
}

class LeftTitleCustomNavigationBar: ChatKeyboardDismissingView, Designable {

    lazy var grabberView = with(UIView()) { view in
        view.backgroundColorThemed = Palette.shared.gray3
        view.layer.cornerRadius = 1.5
    }
    
    lazy var titleLabel: UILabel = self.createTitleLabel()

    lazy var rightButton: UIButton = {
        let button = self.makeButton(imageName: rightButtonImageName)
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.onRightButtonTap?()
        }
        return button
    }()
    
    let title: String?
    
    let rightButtonImageName: String?
    
    let appearance: Appearance
    
    var onRightButtonTap: (() -> Void)?

    init(frame: CGRect = .zero,
         rightButtonImageName: String? = nil,
         title: String? = nil,
         appearance: Appearance = Theme.shared.appearance()) {
        self.appearance = appearance
        self.title = title
        self.rightButtonImageName = rightButtonImageName
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available (*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.fontThemed = Palette.shared.primeFont.with(size: 20, weight: .bold)
        label.text = self.title
        return label
    }
    
    func makeButton(imageName: String?) -> UIButton {
        let button = UIButton()
        button.setImage(
            UIImage(named: imageName ?? "")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.tintColorThemed = self.appearance.tintColor
        return button
    }
    
    func setupView() {
        self.backgroundColor = UIColor.white
    }

    func addSubviews() {
        [
            self.grabberView,
            self.titleLabel,
            self.rightButton
        ].forEach(addSubview)
    }

    func makeConstraints() {
        self.grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(3)
        }

        self.rightButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(18)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(18)
            make.width.greaterThanOrEqualTo(44)
            make.height.equalTo(44)
        }

        self.rightButton.toFront()

        // Temporary solution
        self.rightButton.isHidden = true
    }
}

extension LeftTitleCustomNavigationBar {
    struct Appearance: Codable {
        var tintColor = Palette.shared.brandPrimary
    }
}
